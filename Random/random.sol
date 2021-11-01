// SPDX-License-Identifier: MIT
/** This example code is designed to quickly deploy an example contract using Remix.
 *  If you have never used Remix, try our example walkthrough: https://docs.chain.link/docs/example-walkthrough
 *  You will need testnet ETH and LINK.
 *     - Kovan ETH faucet: https://faucet.kovan.network/
 *     - Kovan LINK faucet: https://kovan.chain.link/
 */

pragma solidity >=0.6.6;

import "./VRFConsumerBase.sol";
import "./IRandom.sol";
import "./Ownable.sol";

contract RandomNumberConsumer is VRFConsumerBase, IRandom, Ownable {

    bytes32 internal keyHash;
    uint256 internal fee;
    uint8 public randomIterations;

    uint256 public randomResult;
    mapping(bytes32  => uint256) public rand;
    mapping(address => bool) private allowedAddrs;
    bytes32 public latestRequest;

    event Request(bytes32 requestId, address user, uint256 poolId, uint256 globalAssetId);
    event Response(bytes32 requestId);


    modifier onlyAllowedAddrs() {
        require(allowedAddrs[msg.sender],
            "Address: should be allowed");
        _;
    }

    /**
     * Constructor inherits VRFConsumerBase
     *
     * Network: Kovan
     * Chainlink VRF Coordinator address: 0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9
     * LINK token address:                0xa36085F69e2889c224210F603D836748e7dC0088
     * Key Hash: 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4
     */
    constructor(uint8 _random)
    VRFConsumerBase(
        0x8C7382F9D8f56b33781fE506E897a4F1e2d17255, // VRF Coordinator polygon
        0x326C977E6efc84E512bB9C30f76E30c160eD06FB  // LINK Token polygon
    ) public
    {
        keyHash = 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4;
        fee = 0.0001 * 10 ** 18; // 0.1 LINK
        randomIterations = _random;
    }


    /**
     * Requests randomness
     */
    function getRandomNumber(address user, uint256 poolId, uint256 globalAssetId) public override onlyAllowedAddrs returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) > fee, "Not enough LINK - fill contract with faucet");
        latestRequest = requestRandomness(keyHash, fee);
        emit Request(latestRequest, user, poolId, globalAssetId);
        return latestRequest;
    }

    function _expand(uint256 randomValue, uint8 randomAmount) internal pure returns (uint256[] memory expandedValues) {
        expandedValues = new uint256[](randomAmount);
        for (uint256 i = 0; i < randomAmount; i++) {
            expandedValues[i] = uint256(keccak256(abi.encode(randomValue, i)));
        }
        return expandedValues;
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        rand[requestId] = randomness;
        emit Response (requestId);
    }
    
    function setIterations(uint8 iter) public onlyOwner {
        randomIterations = iter;
    }
    
    function expandByRequest(bytes32 requestId, uint8 randomAmount) public view returns(uint256[] memory) {
        return _expand(rand[requestId],randomAmount);
    }

    /**
     * Withdraw LINK from this contract
     *
     * DO NOT USE THIS IN PRODUCTION AS IT CAN BE CALLED BY ANY ADDRESS.
     * THIS IS PURELY FOR EXAMPLE PURPOSES.
     */
    function withdrawLink() external onlyOwner {
        require(LINK.transfer(msg.sender, LINK.balanceOf(address(this))), "Unable to transfer");
    }

    function addAllowedAddr(address _contract) public override onlyOwner returns (bool) {
        allowedAddrs[_contract] = true;
        return true;
    }

    function removeAllowedAddr(address _contract) public override onlyOwner returns (bool) {
        allowedAddrs[_contract] = false;
        return true;
    }
}
