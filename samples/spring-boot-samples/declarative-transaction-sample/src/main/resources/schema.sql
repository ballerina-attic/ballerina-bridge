drop table BOOKINGS if exists;
create table BOOKINGS(ID serial, FIRST_NAME varchar(20) NOT NULL);

drop table ROOMS if exists;
create table ROOMS (ID serial, ROOM_NO INT NOT NULL);