package io.ballerina.springboot.samples.programmatic;

import io.ballerina.springboot.TransactionCallbackService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.EnableAutoConfiguration;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Controller;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.TransactionDefinition;
import org.springframework.transaction.TransactionStatus;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.DefaultTransactionDefinition;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;

import javax.sql.DataSource;
import java.util.List;

import static org.springframework.web.bind.annotation.RequestMethod.GET;
import static org.springframework.web.bind.annotation.RequestMethod.POST;


//@Component
@Controller
@EnableAutoConfiguration
public class BookingService {

    private final static Logger logger = LoggerFactory.getLogger(BookingService.class);

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private DataSource dataSource;

    @Autowired
    private PlatformTransactionManager transactionManager;

    public BookingService() {
    }

    @RequestMapping(value = "/reservation/hotel", method = POST)
    public @ResponseBody
    HotelReservationRes reserveHotel(@RequestBody HotelReservationReq req) {
        TransactionDefinition def = new DefaultTransactionDefinition();
        TransactionStatus status = transactionManager.getTransaction(def);
        try {
            String name = req.getFullName();
            reserveRoom(req.getRooms());
            reserveHotel(name);
            transactionManager.commit(status);
            return new HotelReservationRes(10001, "Hotel Reserved for " + name);
        } catch (DataAccessException dae) {
            logger.error("Error in creating record, rolling back");
            transactionManager.rollback(status);
            throw dae;
        }
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

    @RequestMapping(value = "/reservation/room", method = GET)
    @ResponseBody
    public String getReservedRooms() {
        String response = "";
        logger.info("Get ALL reservation rooms");
        for (int roomNo : findAllRooms()) {
            response = response.concat(roomNo + "\n");
        }
        return response;
    }

    void bookHotel(String... persons) {
        for (String person : persons) {
            logger.info("Booking " + person + " in a seat...");
            jdbcTemplate.update("insert into BOOKINGS(FIRST_NAME) values (?)", person);
        }
    }

    void reserveHotel(String... persons) {
        for (String person : persons) {
            logger.info("Booking " + person + " in a room...");
            jdbcTemplate.update("insert into BOOKINGS(FIRST_NAME) values (?)", person);
        }
    }

    void reserveRoom(int roomNo) {
            logger.info("Booking room no: " + roomNo);
            jdbcTemplate.update("insert into ROOMS(ROOM_NO) values (?)", roomNo);
    }


    List<String> findAllBookings() {
        return jdbcTemplate.query("select FIRST_NAME from BOOKINGS",
                (rs, rowNum) -> rs.getString("FIRST_NAME"));
    }

    List<Integer> findAllRooms() {
        return jdbcTemplate.query("select ROOM_NO from ROOMS",
                (rs, rowNum) -> rs.getInt("ROOM_NO"));
    }

    public static void main(String[] args) {
        SpringApplication.run(new Class[]{BookingService.class, TransactionCallbackService.class}, args);
    }
}
