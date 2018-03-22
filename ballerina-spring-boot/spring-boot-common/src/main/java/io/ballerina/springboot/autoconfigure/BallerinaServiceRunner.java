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

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.DisposableBean;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.ApplicationContext;

/**
 * Ballerina Service Runner class.
 * This class gets invoked when starting springboot service with (@Transactional) annotation.
 *
 * @since 1.0.0
 */
public class BallerinaServiceRunner implements CommandLineRunner, DisposableBean {

    private final static Logger logger = LoggerFactory.getLogger(BallerinaServiceRunner.class);

    @Autowired
    ApplicationContext applicationContext;

    @Override
    public void destroy() throws Exception {
        logger.info("Destroying Ballerina Transactional Service");
    }

    public BallerinaServiceRunner() {
    }

    @Override
    public void run(String... args) throws Exception {
        logger.info("Starting Ballerina Transactional Service");
        // Tasks we need to perform automatically when springboot service startup.
    }
}

