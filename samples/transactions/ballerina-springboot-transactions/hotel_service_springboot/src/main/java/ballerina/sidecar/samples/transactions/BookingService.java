/*
*  Copyright (c) 2017, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
*
*  WSO2 Inc. licenses this file to you under the Apache License,
*  Version 2.0 (the "License"); you may not use this file except
*  in compliance with the License.
*  You may obtain a copy of the License at
*
*    http://www.apache.org/licenses/LICENSE-2.0
*
*  Unless required by applicable law or agreed to in writing,
*  software distributed under the License is distributed on an
*  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
*  KIND, either express or implied.  See the License for the
*  specific language governing permissions and limitations
*  under the License.
*/

package ballerina.sidecar.samples.transactions;


import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.SpringApplication;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.boot.autoconfigure.*;
import org.springframework.jdbc.datasource.DataSourceTransactionManager;
import org.springframework.stereotype.Controller;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.TransactionDefinition;
import org.springframework.transaction.TransactionStatus;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.DefaultTransactionDefinition;
import org.springframework.web.bind.annotation.*;

import static org.springframework.web.bind.annotation.RequestMethod.GET;
import static org.springframework.web.bind.annotation.RequestMethod.POST;


//@Component
@Controller
@EnableAutoConfiguration
public class BookingService {

    private final static Logger logger = LoggerFactory.getLogger(BookingService.class);

    private final JdbcTemplate jdbcTemplate;
    private PlatformTransactionManager transactionManager;


    public BookingService(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
        transactionManager = new DataSourceTransactionManager(jdbcTemplate.getDataSource());
    }

    @RequestMapping(value = "/reservation/hotel", method = POST)
    public @ResponseBody
    HotelReservationRes reserveHotel(@RequestBody HotelReservationReq req) {
        String name = req.getFullName();
        reserveHotel(name);
        return new HotelReservationRes(10001, "Hotel Reserved for " + name );
    }

    @RequestMapping(value = "/reservation/hotel", method = GET)
    @ResponseBody
    public String getReservations() {
        String response = "";
        logger.info("Get ALL reservations");
        for (String name : findAllBookings()) {
            response = response.concat(name + "\n");
        }
        return response;
    }


    //Declarative Transactions
    @Transactional
    void bookHotel(String... persons) {
        for (String person : persons) {
            logger.info("Booking " + person + " in a seat...");
            jdbcTemplate.update("insert into BOOKINGS(FIRST_NAME) values (?)", person);
        }
    }

    // Programmatic Transaction Management
    void reserveHotel(String... persons) {

        TransactionDefinition def = new DefaultTransactionDefinition();
        TransactionStatus status = transactionManager.getTransaction(def);

        try {
            for (String person : persons) {
                logger.info("Booking " + person + " in a room...");
                jdbcTemplate.update("insert into BOOKINGS(FIRST_NAME) values (?)", person);
            }
            transactionManager.commit(status);
        } catch (DataAccessException dae) {
            logger.error("Error in creating record, rolling back");
            transactionManager.rollback(status);
            throw dae;
        }
    }


    List<String> findAllBookings() {
        return jdbcTemplate.query("select FIRST_NAME from BOOKINGS",
                (rs, rowNum) -> rs.getString("FIRST_NAME"));
    }

    public static void main(String[] args) {
        SpringApplication.run(BookingService.class, args);
    }
}
