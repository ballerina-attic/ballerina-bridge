package io.ballerina.springboot.samples.programmatic;

public class HotelReservationReq {
    private final String fullName;
    private final String checkIn;
    private final String checkOut;
    private final int rooms;

    public HotelReservationReq() {
        fullName = "";
        checkIn = "";
        checkOut = "";
        rooms = 0;
    }


    public HotelReservationReq(String fullName, String checkIn, String checkOut, int rooms) {
        this.fullName = fullName;
        this.checkIn = checkIn;
        this.checkOut = checkOut;
        this.rooms = rooms;
    }

    public String getFullName() {
        return fullName;
    }

    public String getCheckIn() {
        return checkIn;
    }

    public String getCheckOut() {
        return checkOut;
    }

    public int getRooms() {
        return rooms;
    }
}
