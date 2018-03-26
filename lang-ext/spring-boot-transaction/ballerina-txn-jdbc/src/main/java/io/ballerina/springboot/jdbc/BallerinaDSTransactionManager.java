/*
 *  Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 *  WSO2 Inc. licenses this file to you under the Apache License,
 *  Version 2.0 (the "License"); you may not use this file except
 *  in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing,
 *  software distributed under the License is distributed on an
 *  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 *  KIND, either express or implied.  See the License for the
 *  specific language governing permissions and limitations
 *  under the License.
 */
package io.ballerina.springboot.jdbc;

import io.ballerina.springboot.BallerinaTransactionRegistry;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.datasource.DataSourceTransactionManager;
import org.springframework.stereotype.Component;
import org.springframework.transaction.TransactionDefinition;
import org.springframework.transaction.support.DefaultTransactionStatus;
import org.springframework.transaction.support.TransactionSynchronizationAdapter;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import javax.sql.DataSource;
import java.lang.reflect.Field;
import java.util.HashMap;
import java.util.Map;

import static io.ballerina.springboot.TransactionConstants.PREPARE_ABORTED_RESPONSE;
import static io.ballerina.springboot.TransactionConstants.PREPARE_PREPARED_RESPONSE;

/**
 * Ballerina Data Source Transaction Manager.
 * Holds transactional resources against Ballerina Transactional ID.
 *
 * @since 1.0.0
 */
@Component
public class BallerinaDSTransactionManager extends DataSourceTransactionManager {

    private final static Logger logger = LoggerFactory.getLogger(BallerinaDSTransactionManager.class);
    private static final String NEW_TRANSACTION_FIELD_NAME = "newTransaction";

    public BallerinaDSTransactionManager() {
        super();
    }

    public BallerinaDSTransactionManager(DataSource dataSource) {
        super(dataSource);
    }

    @Override
    protected void doBegin(Object transaction, TransactionDefinition definition) {
        super.doBegin(transaction, definition);
        String txnId = BallerinaTransactionRegistry.getTransactionId();
        if (logger.isDebugEnabled()) {
            logger.debug("Begin Transaction transaction Id: " + txnId);
        }
    }

    @Override
    protected void doCommit(DefaultTransactionStatus status) {
        String txnId = BallerinaTransactionRegistry.getTransactionId();
        if (logger.isDebugEnabled()) {
            logger.debug("Commit Transaction transaction Id: " + txnId);
        }
    }

    @Override
    protected void doRollback(DefaultTransactionStatus status) {
        String txnId = BallerinaTransactionRegistry.getTransactionId();
        if(logger.isDebugEnabled()) {
            logger.debug("Rollback Transaction transaction Id: " + txnId);
        }

        if (txnId != null) {
            BallerinaTransactionRegistry.addTxnStatus(txnId, PREPARE_ABORTED_RESPONSE);
        }
        super.doRollback(status);
    }

    @Override
    protected void prepareForCommit(DefaultTransactionStatus status) {
        super.prepareForCommit(status);
    }

    private Map<Object,Object> getTxnResources() {
        Map<Object, Object> savedResources = new HashMap<>();
        Map<Object, Object> resources = TransactionSynchronizationManager.getResourceMap();

        for (Map.Entry e : resources.entrySet()) {
            savedResources.put(e.getKey(), e.getValue());
            TransactionSynchronizationManager.unbindResource(e.getKey());
        }
        return savedResources;
    }

    @Override
    protected void prepareSynchronization(DefaultTransactionStatus status, TransactionDefinition definition) {

        super.prepareSynchronization(status, definition);
        String txnId = BallerinaTransactionRegistry.getTransactionId();
        if (logger.isDebugEnabled()) {
            logger.debug("Prepare Transaction Synchronization transaction Id: " + txnId);
        }
        if (txnId != null) {
            TransactionSynchronizationManager.registerSynchronization(
                    new TransactionSynchronizationAdapter() {
                        @Override
                        public void beforeCommit(boolean readOnly) {

                            String txnId = BallerinaTransactionRegistry.getTransactionId();
                            BallerinaTransactionRegistry.addTxnResources(txnId, getTxnResources());
                            DefaultTransactionStatus transactionStatus = new DefaultTransactionStatus(status
                                    .getTransaction(), status.isNewTransaction(), status.isNewSynchronization(), status
                                    .isReadOnly(), status.isDebug(), status.getSuspendedResources());
                            BallerinaTransactionRegistry.addTxnObject(txnId, transactionStatus);
                            // This is to disable commit action in the main transaction thread. We should not commit
                            // spring boot transaction. Transaction handles by separate service call(notify) by
                            // transaction initiator.
                            try {
                                // Disabling transaction by setting newTransaction property to false using reflection.
                                Field field = status.getClass().getDeclaredField(NEW_TRANSACTION_FIELD_NAME);
                                field.setAccessible(true);
                                field.set(status, false);
                            } catch (NoSuchFieldException | IllegalAccessException ignore) {
                                logger.error("Internal server error. Failed while disabling commit action in main " +
                                        "thread.");
                            }
                            BallerinaTransactionRegistry.addTxnStatus(txnId, PREPARE_PREPARED_RESPONSE);
                            super.beforeCommit(readOnly);
                        }
                    }
            );
        }
    }
}
