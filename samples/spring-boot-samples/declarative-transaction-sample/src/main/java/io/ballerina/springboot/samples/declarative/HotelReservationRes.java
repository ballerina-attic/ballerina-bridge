package io.ballerina.springboot.samples.declarative;


public class HotelReservationRes {

    private final long id;
    private final String name;

    public HotelReservationRes(long id, String name) {
        this.id = id;
        this.name = name;
    }

    public long getId() {
        return id;
    }

    public String getName() {
        return name;
    }
}
