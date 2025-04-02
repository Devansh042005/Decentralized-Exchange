// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@thirdweb-dev/contracts/base/ERC20Base.sol";

contract DEX is ERC20Base{
    address public token;

    constructor(address _token , address _defaultAdmin , string memory _name, string memory _symbol)
    ERC20Base(_defaultAdmin, _name , _symbol){
        token = _token;
    }

    function getTokensInContract() public view returns (uint){
        return ERC20Base(token).balanceOf(address(this));
    }

    // to add the liquidity
    function addLiquidity(uint256 _amount) public payable returns (uint256){
        uint256 _liquidity;
        uint256 balanceInEth = address(this).balance;
        uint256 tokenReserve = getTokensInContract();
        ERC20Base _token = ERC20Base(token);

        if(tokenReserve == 0){
            _token.transferFrom(msg.sender, address(this), _amount);
            _liquidity = balanceInEth;
            _mint(msg.sender, _amount);
        } else{ // ensuring the liquidity providers add the tokens nd eth proportioanlly to maintain the balance of the pool
            uint256 reservedEth = balanceInEth - msg.value;
            require(
                _amount >= (msg.value * tokenReserve)/ reservedEth,
                "Amount of the tokens sent is less than the minimum token required"
            );
            _token.transferFrom(msg.sender, address(this), _amount);
            unchecked {
                _liquidity = (totalSupply() * msg.value) / reservedEth;
            }
            _mint(msg.sender, _liquidity);
        }
        return _liquidity;
    }

    // removing the liquidity
    function removeLiquidity(uint256 _amount) public returns (uint256 ,  uint256){
        require(_amount > 0, "Amount should be greater than zero");
        uint256 _reservedEth = address(this).balance;
        uint256 _totalSupply = totalSupply();

        uint256 _ethAmount = (_reservedEth * _amount)/ totalSupply();
        uint256 _tokenAmount = (getTokensInContract() * _amount) / _totalSupply;
        _burn(msg.sender, _amount);
        payable(msg.sender).transfer(_ethAmount);
        ERC20Base(token).transfer(msg.sender , _tokenAmount);
        return(_ethAmount , _tokenAmount);
    }

    // function to get the amount of tokens after the swap

    function getAmountOfTokens(
        uint256 inputAmount, // amount of tokens user want to swap
        uint256 inputReserve, // liquidity reserve of token being swapped from
        uint256 outputReserve // liquidity reserve of token being swapped to
    ) public pure returns (uint256){
        require(inputReserve > 0 && outputReserve > 0 , "Invalid Reserves");
        uint256 numerator = inputAmount * outputReserve;
        uint256 denominator = (inputReserve * 100) + inputAmount;
        unchecked{ // unchecked here helps to reduce the gas costs
            return numerator / denominator;
        }
    }

    function swapEthToToken() public payable {
        uint256 _reservedToken = getTokensInContract();
        uint256 _tokensBought = getAmountOfTokens(msg.value, address(this).balance, _reservedToken);

        ERC20Base(token).transfer(msg.sender, _tokensBought);
    }

    function swapTokenToEth(uint256 _tokenSold) public {
        uint256 _reservedTokens = getTokensInContract();
        uint256 ethBought = getAmountOfTokens(_tokenSold, address(this).balance, _reservedTokens);
        ERC20Base(token).transferFrom(msg.sender, address(this), _tokenSold);
        payable(msg.sender).transfer(ethBought);
    }
    
}