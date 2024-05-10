// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {FlashLoanSimpleReceiverBase} from "@aave/core-v3/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {IERC20} from "@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol";

interface IChallenge {
    function Try(string memory _response) external payable;
}

interface IWETH {
    function deposit() external payable;
    function withdraw(uint wad) external;
}


contract FlashLoan is FlashLoanSimpleReceiverBase {
    address payable public owner;
    IWETH public weth;
    IChallenge public challengeContract;

    constructor(
        address _addressProvider,
        address _challengeContract,
        address _wethAddress // Address of the WETH token contract
    )
        FlashLoanSimpleReceiverBase(IPoolAddressesProvider(_addressProvider))
    {
        owner = payable(msg.sender);
        challengeContract = IChallenge(_challengeContract);
        weth = IWETH(_wethAddress); // WETH contract
    }

    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        require(msg.sender == address(POOL), "Caller must be pool");

        // Convert WETH to ETH
        weth.withdraw(amount);

        // Call the challenge contract with the correct response
        
        challengeContract.Try{value: amount}("A barbeR");

        // Calculate the total owed amount including the premium
        uint256 amountOwed = amount + premium;

        // Re-convert ETH to WETH by depositing back to the WETH contract
        // This assumes the WETH contract accepts ETH deposits directly
        IWETH(asset).deposit{value: amountOwed}();

        // Approve the pool to take back the owed amount
        IERC20(asset).approve(address(POOL), amountOwed);

        return true;
    }

    function requestFlashLoan(address _token, uint256 _amount) public onlyOwner {
        address receiverAddress = address(this);
        address asset = _token;
        uint256 amount = _amount;
        bytes memory params = "";
        uint16 referralCode = 0;

        POOL.flashLoanSimple(
            receiverAddress,
            asset,
            amount,
            params,
            referralCode
        );
    }

     function withdrawAllETH() external onlyOwner {
        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            (bool sent, ) = owner.call{value: ethBalance}("");
            require(sent, "Failed to send Ether");
        }
    }

    function withdraw(address _tokenAddress) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the contract owner can call this function"
        );
        _;
    }

    receive() external payable {}

    fallback() external payable {
        require(msg.data.length == 0);
        IWETH(weth).deposit{value: msg.value}();
    }
}
