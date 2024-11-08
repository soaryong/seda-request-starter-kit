// SPDX-License-Identifier: MIT
// NOTICE: This is an example contract with no security considerations taken into account.
// This contract is for educational purposes only and should not be used in production environments.

pragma solidity 0.8.25;

import "@seda-protocol/contracts/src/SedaProver.sol";

/**
 * @title PriceFeed
 * @notice This contract demonstrates how to create and interact with data requests on the SEDA network.
 * It interacts with the SedaProver contract for transmitting data requests and fetching results.
 */
contract Seda {
    // ID of the most recent data request.
    bytes32 public dataRequestId;
    bytes32 public dataRequestId2;

    // ID of the data request WASM binary on the SEDA network.
    bytes32 public oracleProgramId;

    address public owner;
    uint256 public lastPaid;

    // 한 달에 해당하는 시간 (30일 * 24시간 * 60분 * 60초)
    uint256 constant MONTH_IN_SECONDS = 30 days;

    // Instance of the SedaProver contract, which verifies the authenticity of data request results.
    SedaProver public sedaProverContract;


    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can execute this.");
        _;
    }

    constructor(address _sedaProverContract, bytes32 _oracleProgramId) {
        sedaProverContract = SedaProver(_sedaProverContract);
        oracleProgramId = _oracleProgramId;
        owner = msg.sender;
        lastPaid = block.timestamp - 60 days;
    }

    /**
     * @notice Triggers the transmission of new data request to the SEDA network through the SedaProver contract.
     * @dev This function sends a request to fetch the price of the ETH-USDC pair from the SEDA network.
     * @return The ID of the newly created data request.
     */
    function transmit() public returns (bytes32) {
        SedaDataTypes.DataRequestInputs memory inputs = SedaDataTypes
            .DataRequestInputs(
            oracleProgramId,                // Oracle Program ID (0x...)
            "1",                     // Inputs for the data request (ETH-USDC)
            oracleProgramId,                // Tally binary ID (same as DR binary ID in this example)
            hex"00",                        // Tally inputs
            1,                              // Replication factor (number of nodes required to execute the DR)
            hex"00",                        // Consensus filter (set to `None`)
            1,                              // Gas price
            5000000,                        // Gas limit
            abi.encodePacked(block.number)  // Additional info (block number as memo)
        );

        // Post the data request to the SedaProver contract and store the request ID.
        dataRequestId = sedaProverContract.postDataRequest(inputs);

        SedaDataTypes.DataRequestInputs memory inputs2 = SedaDataTypes
            .DataRequestInputs(
            oracleProgramId,                // Oracle Program ID (0x...)
            "2",                     // Inputs for the data request (ETH-USDC)
            oracleProgramId,                // Tally binary ID (same as DR binary ID in this example)
            hex"00",                        // Tally inputs
            1,                              // Replication factor (number of nodes required to execute the DR)
            hex"00",                        // Consensus filter (set to `None`)
            1,                              // Gas price
            5000000,                        // Gas limit
            abi.encodePacked(block.number)  // Additional info (block number as memo)
        );

        dataRequestId2 = sedaProverContract.postDataRequest(inputs2);

        return dataRequestId;
    }

    /**
     * @notice Fetches the latest answer for the data request from the SEDA network.
     * @dev This function retrieves the result of the last data request and returns the price if consensus was reached.
     * @return The latest price as a uint128, or 0 if no consensus was reached or if no request has been transmitted.
     */
    function latestAnswer() public view returns (address) {
        // Ensure a data request has been transmitted.
        require(dataRequestId != bytes32(0), "No data request transmitted");
        require(dataRequestId2 != bytes32(0), "No data request transmitted");

        // Fetch the data result from the SedaProver contract using the stored data request ID.
        SedaDataTypes.DataResult memory dataResult = sedaProverContract
            .getDataResult(dataRequestId);

        SedaDataTypes.DataResult memory dataResult2 = sedaProverContract
            .getDataResult(dataRequestId2);

        // Check if the data result reached consensus (≥ 66% agreement among nodes).
        if (dataResult.consensus) {
            bytes16 part1 = bytes16(dataResult.result);
            bytes16 part2 = bytes16(dataResult2.result);

            // bytes16을 bytes로 변환한 뒤, 슬라이싱하여 마지막 10바이트 추출
            bytes memory part1Bytes = abi.encodePacked(part1);
            bytes memory part2Bytes = abi.encodePacked(part2);

            // 마지막 10바이트 추출 (bytes[6:]는 6번째 인덱스부터 끝까지 추출)
            bytes memory last10Bytes1 = new bytes(10);
            bytes memory last10Bytes2 = new bytes(10);

            // part1Bytes와 part2Bytes에서 각각 마지막 10바이트를 추출하여 할당
            for (uint i = 0; i < 10; i++) {
                last10Bytes1[i] = part1Bytes[i + 6]; // part1에서 6번째부터 10바이트
                last10Bytes2[i] = part2Bytes[i + 6]; // part2에서 6번째부터 10바이트
            }

            // 10바이트씩 합쳐서 20바이트 만들기
            bytes20 combined = bytes20(abi.encodePacked(last10Bytes1, last10Bytes2));


            // 이더리움 주소로 변환
            return address(uint160(combined));
        }

        // Return 0 if no valid result or no consensus.
        return address(0);
    }

    function sendMonthlyPayment() public onlyOwner {
        address recipient = latestAnswer();
        require(block.timestamp >= lastPaid + MONTH_IN_SECONDS, "It's not yet time for the next payment.");

        payable(recipient).transfer(0.1 ether);

        lastPaid = block.timestamp;
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    receive() external payable {}
}
