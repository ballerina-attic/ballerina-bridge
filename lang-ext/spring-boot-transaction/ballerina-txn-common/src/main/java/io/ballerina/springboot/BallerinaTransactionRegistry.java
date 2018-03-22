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

import org.springframework.transaction.support.DefaultTransactionStatus;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Ballerina Transaction Registry.
 * Holds transactional resources against Ballerina Transactional ID.
 *
 * @since 1.0.0
 */
public class BallerinaTransactionRegistry {

    private static ThreadLocal<String> localTransactionID = new ThreadLocal<>();
    private static Map<String, DefaultTransactionStatus> transactionObjectMap = new ConcurrentHashMap<>();
    private static Map<String, Map<Object, Object>> transactionResourceMap = new ConcurrentHashMap<>();
    private static Map<String, String> transactionStatusMap = new ConcurrentHashMap<>();

    public static String getTransactionId() {
        return localTransactionID.get();
    }

    public static void setTransactionId(String transactionId) {
        localTransactionID.set(transactionId);
    }

    public static void cleanup() {
        localTransactionID.remove();
    }

    // Transaction resource map
    public static void addTxnResources(String txnID, Map<Object, Object> resources) {
        transactionResourceMap.put(txnID, resources);
    }

    public static Map<Object, Object> getTxnResources(String txnID) {
        return transactionResourceMap.get(txnID);
    }

    public static void removeTxnResources(String txnID) {
        transactionResourceMap.remove(txnID);
    }

    public static boolean containsTxnResources(String txnID) {
        return transactionResourceMap.containsKey(txnID);
    }

    // Transaction status
    public static void addTxnStatus(String txnID, String txnStatus) {
        transactionStatusMap.put(txnID, txnStatus);
    }

    public static String getTxnStatus(String txnID) {
        return transactionStatusMap.get(txnID);
    }

    public static void removeTxnStatus(String txnID) {
        transactionStatusMap.remove(txnID);
    }

    public static boolean containsTxnStatus(String txnID) {
        return transactionStatusMap.containsKey(txnID);
    }

    // Transaction Object
    public static void addTxnObject(String txnID, DefaultTransactionStatus txnObject) {
        transactionObjectMap.put(txnID, txnObject);
    }

    public static DefaultTransactionStatus getTxnObject(String txnID) {
        return transactionObjectMap.get(txnID);
    }

    public static void removeTxnObject(String txnID) {
        transactionObjectMap.remove(txnID);
    }

    public static boolean containsTxnObject(String txnID) {
        return transactionObjectMap.containsKey(txnID);
    }
}
