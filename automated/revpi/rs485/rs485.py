#!/usr/bin/env python3

"""
Test the RS485 functionality of a device.

This is split into 2 modes: "server" and "client". Both modes send and receive
messages.

The server waits (infinitely if the limit is set to 0) for RS485 packets and
checks the CRC for an error. Error or not, it always responds to the packet by
sending one to the client. If an invalid CRC was detected this is given as the
payload.

The client sends RS485 packets and waits for an answer from the server.
Once done sending the given amount of packets the client prints the amount of
transmission errors and exits with an exit status of 1.
"""

import argparse
import crcmod.predefined
import enum
import random
import serial
import struct
import sys
from typing import Union

CRC32_FUNC = crcmod.predefined.mkCrcFun("crc-32")


class PacketType(enum.Enum):
    Data = 0
    Ack = 1
    Error = 2


class PacketError(enum.Enum):
    InvalidCrc = 0


PacketData = Union[int, PacketError, None]


class RS485Packet:
    def __init__(self, ty: PacketType, data: PacketData, crc: int):
        """
        Construct an RS485 packet given the data and crc.

        :param PacketType ty: The type of the packet.
        :param PacketData data: The data, can be one of multiple types.
        :param int crc: The CRC of the whole packet (excluding the CRC itself).
        This must be a 32-bit unsigned integer
        :return: The RS485 packet
        """

        self.__ty = ty
        self.__data = data
        self.__crc = crc

    @classmethod
    def new_ack(cls):
        """
        Create a new ACK packet.

        The payload of the ACK packet is empty (0).
        """

        o = cls(PacketType.Ack, 0, 0)
        o.recalc_crc()

        return o

    @classmethod
    def from_data(cls, data: int):
        """
        Construct an RS485 packet given some data in the form of an integer.

        :param int data: The data. This must be a 32-bit unsigned integer.
        :return: the RS485 packet
        """

        o = cls(PacketType.Data, data, 0)
        o.recalc_crc()

        return o

    @classmethod
    def from_error(cls, error: PacketError):
        """
        Construct an RS485 error packet, given an error.

        :param PacketError error: The error this packet should transmit.
        :return: the RS485 error packet
        """

        o = cls(PacketType.Error, error, 0)
        o.recalc_crc()

        return o

    @property
    def ty(self) -> PacketType:
        return self.__ty

    @property
    def data(self) -> PacketData:
        return self.__data

    @data.setter
    def data(self, data: PacketData):
        self.__data = data

    @property
    def crc(self) -> int:
        return self.__crc

    def to_struct(self) -> bytes:
        """
        Construct a byte object from a RS485Packet.

        :return: The byte representation of the RS485 packet.
        """

        data = 0
        if self.__data is None:
            data = 0
        elif isinstance(self.__data, int):
            data = self.__data
        elif self.__data is PacketError:
            data = self.__data.value

        s = struct.pack("!BII", self.__ty.value, data, self.__crc)
        return s

    @classmethod
    def from_struct(cls, s: bytes):
        """
        Construct an RS485 packet from a struct.

        :param bytes s: The struct that should be converted into an RS485
        packet.
        """

        assert len(s) == 9
        (_ty, _data, crc) = struct.unpack("!BII", s)

        ty = PacketType(_ty)
        if ty is PacketType.Data:
            data = _data
        elif ty is PacketType.Error:
            data = PacketError(_data)
        elif ty is PacketType.Ack:
            data = None

        return cls(ty, data, crc)

    def calc_crc(self) -> int:
        """
        Calculate the CRC of the packet.

        :return: The CRC
        """

        data = 0
        if self.__data is None:
            data = 0
        elif isinstance(self.__data, int):
            data = self.__data
        elif self.__data is PacketError:
            data = self.__data.value

        return CRC32_FUNC(bytes(self.__ty.value) + bytes(data))

    def recalc_crc(self):
        """
        Recalculate the CRC of the packet. This is stored inside the object.
        """

        self.__crc = self.calc_crc()

    def is_valid(self) -> bool:
        """
        Validate the packet by comparing the stored CRC with a newly computed
        one.

        :return: True if valid, False if invalid
        """

        return self.calc_crc() == self.__crc


class Mode(enum.Enum):
    Client = "client"
    Server = "server"

    def __str__(self):
        return self.value


def serial_client(ser: serial.Serial, timeout: float, limit: int) -> int:
    """
    Send limit amount of packets to over the RS485 connection.

    :param serial.Serial ser: The serial device used for sending and receiving
    packets.
    :param float timeout: The amount of time the client waits for an error
    response from the server.
    :param int limit: Amount of packets to send.
    :return: Amount of errors that occurred.
    """

    count = 0
    error = 0
    ser.timeout = timeout
    while count < limit:
        packet = RS485Packet.from_data(random.randint(0, 65536))
        packet = packet.to_struct()
        ser.write(packet)
        count = count + 1

        resp = ser.read(9)
        # response *has* to be sent by the server
        if len(resp) == 0:
            print("No response received", file=sys.stderr)
            error = error + 1
        elif len(resp) != 9:
            print("Malformed response from server", file=sys.stderr)
            error = error + 1
        else:
            rs485_packet = RS485Packet.from_struct(resp)
            if not rs485_packet.is_valid():
                print("Broken error response from server", file=sys.stderr)
                error = error + 1
            elif rs485_packet.ty == PacketType.Error:
                error = error + 1

    return error


def serial_server(ser: serial.Serial, limit: int) -> int:
    """
    Start the server to validate RS485 packets. If given a limit > 0, the
    server will only accept "limit" amount of packets before exiting.
    Additionally, if no packet is received during 60 seconds, it will exit.

    :param serial.Serial ser: The serial device used for receiving and sending
    packets.
    :param int limit: The amount of packets to process. A limit of 0 sets no
    limit and runs the server indefinitely.
    :return: Amount of errors that occurred.
    """

    count = 0
    error = 0

    # Set a 60-second timeout for receiving packets
    ser.timeout = 60

    while True:
        if limit > 0 and count >= limit:
            break

        packet = ser.read(9)

        if len(packet) == 0:
            print("Timeout: No packet received for 60 seconds, exiting server.", file=sys.stderr)
            break

        rs485_packet = RS485Packet.from_struct(packet)
        count = count + 1

        if not rs485_packet.is_valid():
            packet = RS485Packet.from_error(PacketError.InvalidCrc).to_struct()
            ser.write(packet)
            error = error + 1
        else:
            packet = RS485Packet.new_ack().to_struct()
            ser.write(packet)

    return error


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("device")
    parser.add_argument(
        "mode",
        type=Mode,
        choices=list(Mode),
        default=Mode.Client,
    )
    parser.add_argument(
        "-b",
        default=19200,
        type=int,
        help="baudrate for interface",
        metavar="baudrate",
        dest="baudrate",
    )
    parser.add_argument(
        "-t",
        default=0.1,
        type=float,
        help="timeout for sender to receive error responses before sending again",
        metavar="timeout",
        dest="timeout",
    )
    parser.add_argument(
        "-l",
        type=int,
        help="Amount of messages to send/receive",
        metavar="limit",
        dest="limit",
        default=20,
    )
    args = parser.parse_args()

    error = 0
    ser = serial.Serial(args.device, baudrate=args.baudrate)

    if ser.in_waiting > 0:
        ser.read(ser.in_waiting)

    if args.mode == Mode.Client:
        error = serial_client(ser, args.timeout, args.limit)
    elif args.mode == Mode.Server:
        error = serial_server(ser, args.limit)

    ser.close()
    print(f"{error}")
    sys.exit(1 if error > 0 else 0)


if __name__ == "__main__":
    main()
