//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./base/UniversalChanIbcApp.sol";
import {ERC20Token} from "./ERC20Tokens.sol";

contract Gateway is UniversalChanIbcApp {
    error InsufficientBalance();
    // application specific state
    uint64 public counter;
    mapping(uint64 => address) public counterMap;
    address private tokenAddress;

    event TransferDone(uint256 indexed _amount, uint64 indexed _counter);

    constructor(
        address _middleware,
        address _tokenAddress
    ) UniversalChanIbcApp(_middleware) {
        tokenAddress = _tokenAddress;
    }

    // application specific logic
    function resetCounter() internal {
        counter = 0;
    }

    function increment() internal {
        counter++;
    }

    function _mintToken(address _to, uint256 _amount) private {
        ERC20Token(tokenAddress).mint(_to, _amount);
    }

    function _burnToken(address _from, uint256 _amount) private {
        if (ERC20Token(tokenAddress).balanceOf(_from) < _amount) {
            revert InsufficientBalance();
        }
        ERC20Token(tokenAddress).burn(_from, _amount);
    }

    // IBC logic

    /**
     * @dev Sends a packet with the caller's address over the universal channel.
     * @param destPortAddr The address of the destination application.
     * @param channelId The ID of the channel to send the packet to.
     * @param timeoutSeconds The timeout in seconds (relative).
     * @param _amount the amount of token to be transfered
     */
    function sendUniversalPacket(
        address destPortAddr,
        bytes32 channelId,
        uint64 timeoutSeconds,
        uint256 _amount
    ) external {
        increment();
        _burnToken(msg.sender, _amount);
        bytes memory payload = abi.encode(msg.sender, counter, _amount);

        uint64 timeoutTimestamp = uint64(
            (block.timestamp + timeoutSeconds) * 1000000000
        );

        IbcUniversalPacketSender(mw).sendUniversalPacket(
            channelId,
            IbcUtils.toBytes32(destPortAddr),
            payload,
            timeoutTimestamp
        );
    }

    /**
     * @dev Packet lifecycle callback that implements packet receipt logic and returns and acknowledgement packet.
     *      MUST be overriden by the inheriting contract.
     *
     * @param channelId the ID of the channel (locally) the packet was received on.
     * @param packet the Universal packet encoded by the source and relayed by the relayer.
     */
    function onRecvUniversalPacket(
        bytes32 channelId,
        UniversalPacket calldata packet
    ) external override onlyIbcMw returns (AckPacket memory ackPacket) {
        recvedPackets.push(UcPacketWithChannel(channelId, packet));

        (address payload, uint64 c, uint256 _amount) = abi.decode(
            packet.appData,
            (address, uint64, uint256)
        );
        counterMap[c] = payload;
        _mintToken(payload, _amount);

        increment();

        return AckPacket(true, abi.encode(counter, _amount));
    }

    /**
     * @dev Packet lifecycle callback that implements packet acknowledgment logic.
     *      MUST be overriden by the inheriting contract.
     *
     * @param channelId the ID of the channel (locally) the ack was received on.
     * @param packet the Universal packet encoded by the source and relayed by the relayer.
     * @param ack the acknowledgment packet encoded by the destination and relayed by the relayer.
     */
    function onUniversalAcknowledgement(
        bytes32 channelId,
        UniversalPacket memory packet,
        AckPacket calldata ack
    ) external override onlyIbcMw {
        ackPackets.push(UcAckWithChannel(channelId, packet, ack));

        // decode the counter from the ack packet
        (uint64 _counter, uint256 _amount) = abi.decode(
            ack.data,
            (uint64, uint256)
        );

        emit TransferDone(_amount, _counter);

        if (_counter != counter) {
            resetCounter();
        }
    }

    /**
     * @dev Packet lifecycle callback that implements packet receipt logic and return and acknowledgement packet.
     *      MUST be overriden by the inheriting contract.
     *      NOT SUPPORTED YET
     *
     * @param channelId the ID of the channel (locally) the timeout was submitted on.
     * @param packet the Universal packet encoded by the counterparty and relayed by the relayer
     */
    function onTimeoutUniversalPacket(
        bytes32 channelId,
        UniversalPacket calldata packet
    ) external override onlyIbcMw {
        timeoutPackets.push(UcPacketWithChannel(channelId, packet));
        // do logic
    }
}
