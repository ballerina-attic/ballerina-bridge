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
package io.ballerina.springboot.autoconfigure;

import io.ballerina.springboot.interceptor.BallerinaInterceptorAdapter;
import org.springframework.boot.autoconfigure.AutoConfigureOrder;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.transaction.interceptor.TransactionInterceptor;

/**
 * Ballerina Auto Configuration Class.
 * This is triggered when registering spring boot service.
 *
 * @since 1.0.0
 */
@AutoConfigureOrder
@Import({ BallerinaInterceptorAdapter.class })
public class BallerinaAutoConfiguration {

    @Bean
    public BallerinaServiceRunner ballerinaServiceRunner() {
        return new BallerinaServiceRunner();
    }

    @Bean
    @ConditionalOnMissingBean(TransactionInterceptor.class)
    public TransactionInterceptor transactionInterceptor() {
        return new TransactionInterceptor();
    }
}
