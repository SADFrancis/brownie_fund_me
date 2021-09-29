// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

// refer to brownie-config.yaml for the chainlink imports
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

contract FundMe {
    using SafeMathChainlink for uint256;

    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    function fund() public payable {
        uint256 minimumUSD = 50 * 10**18; //50 converted to base wei thanks to getPrice() function
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You need to spend more ETH!"
        );
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
         // retrieving the chainlink pricefeed contract for ETH
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000); // to convert from Gwei to Wei (a full 10^18)
    }

    // 1000000000 Wei == 1 Gwei
    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        // Getprice returns in 10^9 Wei, ethAmount is also in X * 10^9 Wei
        //need to divide out by 10^18 to get eth Amount in USD
        // perks of not having decimals in Solidity.
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd; // returns in Gwei
    }

    function getEntranceFee() public view returns (uint256){
        //minimumUSD
        uint256 minimumUSD = 50 * 10 ** 18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10 ** 18;
        return (minimumUSD * precision) / price;
    }

    modifier onlyOwner() { // streamline the requirement to be the owner of the contract to execute a function
        require(msg.sender == owner);
        _;
    }

    function withdraw() public payable onlyOwner { // OnlyOwner is important for this to prevent others from withdrawing
        msg.sender.transfer(address(this).balance);

        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) { 
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0); // clearing out address array of funders
    }
}
