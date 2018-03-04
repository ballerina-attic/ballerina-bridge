package ballerina.sidecar.samples.transactions;


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
