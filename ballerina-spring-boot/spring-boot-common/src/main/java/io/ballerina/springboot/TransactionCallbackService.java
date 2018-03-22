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
package io.ballerina.springboot;

import io.ballerina.springboot.bean.NotifyRequest;
import io.ballerina.springboot.bean.NotifyResponse;
import io.ballerina.springboot.bean.PrepareRequest;
import io.ballerina.springboot.bean.PrepareResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.EnableAutoConfiguration;
import org.springframework.dao.DataAccessException;
import org.springframework.stereotype.Controller;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.TransactionDefinition;
import org.springframework.transaction.TransactionStatus;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.DefaultTransactionDefinition;
import org.springframework.transaction.support.DefaultTransactionStatus;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;

import javax.servlet.http.HttpServletRequest;
import java.util.Map;

import static io.ballerina.springboot.TransactionConstants.NOTIFY_ABORTED_RESPONSE;
import static io.ballerina.springboot.TransactionConstants.NOTIFY_COMMITTED_RESPONSE;
import static io.ballerina.springboot.TransactionConstants.NOTIFY_COMMIT_REQUEST;
import static io.ballerina.springboot.TransactionConstants.PREPARE_ABORTED_RESPONSE;
import static org.springframework.web.bind.annotation.RequestMethod.POST;

/**
 * Transactional Callback Service.
 * Handles Prepare and Notify requests from Ballerina coordinator.
 *
 * @since 1.0.0
 */
@EnableAutoConfiguration
@Controller
@RequestMapping("/transaction")
public class TransactionCallbackService {

    @Autowired
    HttpServletRequest request;

    @Autowired
    private PlatformTransactionManager transactionManager;

    private final static Logger logger = LoggerFactory.getLogger(TransactionCallbackService.class);

    public TransactionCallbackService(PlatformTransactionManager transactionManager) {
    }

    @RequestMapping(value = "/prepare", method = POST)
    @ResponseBody
    PrepareResponse prepare(@RequestBody PrepareRequest input) {
        if (logger.isDebugEnabled()) {
            logger.debug("Incoming prepared request: " + input.toString());
        }
        String txnID = input.getTransactionId();
        PrepareResponse response = new PrepareResponse();
        if (txnID == null) {
            logger.error("Transaction Aborted. request transaction id is null");
            response.setMessage(PREPARE_ABORTED_RESPONSE);
            return response;
        }

        if (!(BallerinaTransactionRegistry.containsTxnObject(txnID) && BallerinaTransactionRegistry
                .containsTxnResources(txnID) && BallerinaTransactionRegistry.containsTxnStatus(txnID))) {
            logger.error("Transaction Aborted. Transaction details not found for the requested id");
            response.setMessage(PREPARE_ABORTED_RESPONSE);
            return response;
        }

        DefaultTransactionStatus transactionStatus = BallerinaTransactionRegistry.getTxnObject(txnID);
        if (!(transactionStatus.isNewTransaction() && transactionStatus.isNewSynchronization())) {
            logger.error("Transaction Aborted. Transaction resource not marked as new or synchronization");
            response.setMessage(PREPARE_ABORTED_RESPONSE);
            return response;
        }

        String txnStatus = BallerinaTransactionRegistry.getTxnStatus(txnID);
        response.setMessage(txnStatus);
        if (logger.isDebugEnabled()) {
            logger.debug("Outgoing prepared response: " + response);
        }
        return response;
    }

    @RequestMapping(value = "/notify", method = POST)
    @ResponseBody
    @Transactional
    NotifyResponse complete(@RequestBody NotifyRequest input) {
        if (logger.isDebugEnabled()) {
            logger.debug("Incoming prepared request: " + input.toString());
        }
        String txnID = input.getTransactionId();
        NotifyResponse response = new NotifyResponse();
        TransactionDefinition definition = new DefaultTransactionDefinition(TransactionDefinition.PROPAGATION_NESTED);
        Map<Object, Object> txnResources = BallerinaTransactionRegistry.getTxnResources(txnID);
        for (Map.Entry e : txnResources.entrySet()) {
            TransactionSynchronizationManager.bindResource(e.getKey(), e.getValue());
        }
        TransactionStatus status = BallerinaTransactionRegistry.getTxnObject(txnID);

        TransactionSynchronizationManager.setCurrentTransactionIsolationLevel(
                definition.getIsolationLevel() != TransactionDefinition.ISOLATION_DEFAULT ?
                        definition.getIsolationLevel() : null);
        TransactionSynchronizationManager.setCurrentTransactionReadOnly(definition.isReadOnly());
        TransactionSynchronizationManager.setCurrentTransactionName(definition.getName());
        TransactionSynchronizationManager.initSynchronization();

        try {
            if (NOTIFY_COMMIT_REQUEST.equals(input.getMessage())) {
                transactionManager.commit(status);
                response.setMessage(NOTIFY_COMMITTED_RESPONSE);
            } else {
                transactionManager.rollback(status);
                response.setMessage(NOTIFY_ABORTED_RESPONSE);
            }
        } catch (DataAccessException dae) {
            System.out.println("Error in creating record, rolling back");
            transactionManager.rollback(status);
            response.setMessage(NOTIFY_ABORTED_RESPONSE);
            throw dae;
        } finally {
            for (Map.Entry e : txnResources.entrySet()) {
                TransactionSynchronizationManager.unbindResourceIfPossible(e);
            }
            BallerinaTransactionRegistry.removeTxnResources(txnID);
            BallerinaTransactionRegistry.removeTxnObject(txnID);
            BallerinaTransactionRegistry.removeTxnStatus(txnID);
        }
        return response;
    }
}
