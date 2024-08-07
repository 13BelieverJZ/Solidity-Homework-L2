// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract BtcToken {
    string private _name;
    string private _symbol;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address public owner;

    event Transfer(address indexed from,address indexed to,uint256 value);
    event Approval(address indexed owenr,address indexed spender,uint256 value);

    constructor() {
        _name = "Bitcoin";
        _symbol = "BTC";
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owenr");
        _;
    }

    function name() public view returns (string memory){
        return _name;
    }

    function symbol() public view returns (string memory){
        return _symbol;
    }

    function decimals() public pure returns (uint8){
        return 18;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns(uint256){
        return _balances[account];
    }

    function allowance(address _owner,address _spender) public view returns(uint256) {
        return _allowances[_owner][_spender];
    }

    function approve(address spender, uint256 amount) public {
        _allowances[owner][spender] += amount;
        emit Approval(owner, spender, amount);
    }

    function transfer(address to,uint256 amount) public {
        require(_balances[msg.sender] >= amount);
        _balances[msg.sender] -= amount;
        _balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
    }

    function tranferFrom(address from, address to, uint256 amount) public {
        uint256 alc = _allowances[from][msg.sender];
        require(alc >= amount,"Allowance exceeded");
        require(_balances[from] >= amount, "Insufficient balance");

        _balances[from] -= amount;
        _balances[from] += amount;
        _allowances[from][msg.sender] += amount;

        emit Transfer(from, to, amount);
    }

    function mint(address account, uint256 amount) public onlyOwner {
        _balances[account] += amount;
        _totalSupply += amount;
        emit Transfer(address(0), account, amount);
    }

    function burn(address account, uint256 amount) public onlyOwner {
        require(_balances[account] >= amount,"Insufficient balance to burn");
        _balances[account] -= amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount); 
    }

} 