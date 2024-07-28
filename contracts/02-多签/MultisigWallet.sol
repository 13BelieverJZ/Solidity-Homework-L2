// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// 0x014db45aa753fefeca3f99c2cb38435977ebb954f779c2b6af6f6365ba4188df542031ace9bdc53c655ad2d4794667ec2495196da94204c56b1293d0fbfacbb11cbe2e0e6de5574b7f65cad1b7062be95e7d73fe37dd8e888cef5eb12e964ddc597395fa48df1219e7f74f48d86957f545d0fbce4eee1adfbaff6c267046ade0d81c
contract MultisigWallet {

    address[] public owners; // 多签持有人
    mapping(address => bool) public isOwner; // 记录一个地址是否为多签持有人
    uint256 public ownerCount; // 多签持有人的数量
    uint256 public threshold; // 多签执行门槛，交易至少有n个多签人签名才能被执行
    uint256 public nonce; // 防止签名重放攻击

    event ExecutionSuccess(bytes32 txHash);    // 交易成功事件
    event ExecutionFailure(bytes32 txHash);    // 交易失败事件

    receive() external payable {}
    constructor(
        address[] memory _owners,
        uint256 _threshod
    ){
        _setupOwners(_owners,_threshod);
    }

    function _setupOwners(address[] memory _owners, uint256 _threshold) internal  {
        require(threshold == 0,"DQ500");
        require(_threshold <= _owners.length,"DQ501");
        require(_threshold >= 1,"DQ502");

        for(uint256 i = 0; i < _owners.length; i++){
            address owner = _owners[i];
            require(owner != address(0) && owner != address(this) && !isOwner[owner],"DQ503");

            owners.push(owner);
            isOwner[owner] = true;
        }
        ownerCount = _owners.length;
        threshold = _threshold;
    }

    function execTransation(
        address to,
        uint256 value,
        bytes memory data,
        bytes memory signatures
    ) public payable virtual returns(bool success){
        // 编码交易数据，计算哈希
        bytes32 txHash = encodeTransactionData(to, value, data, nonce, block.chainid);
        nonce++;
        checkSignatures(txHash, signatures); // 检查签名
        // 利用call执行交易，并获取交易结果
        (success, ) = to.call{value: value}(data);
        require(success , "DQ5004");
        if (success) emit ExecutionSuccess(txHash);
        else emit ExecutionFailure(txHash);
    }

    function encodeTransactionData(
        address to,
        uint256 value,
        bytes memory data,
        uint256 _nonce,
        uint256 chainid
    ) public pure returns (bytes32) {
        bytes32 safeTxHash =
            keccak256(
                abi.encode(
                    to,
                    value,
                    keccak256(data),
                    _nonce,
                    chainid
                )
            );
        return safeTxHash;
    }

        /**
    * @dev 检查签名和交易数据是否对应。如果是无效签名，交易会revert
    * @param dataHash 交易数据哈希
    * @param signatures 几个多签签名打包在一起
    */
    function checkSignatures(
        bytes32 dataHash,
        bytes memory signatures
    ) public view {
        // 读取多签执行门槛
        uint256 _threshold = threshold;
        require(_threshold > 0, "DQ5005");

        // 检查签名长度足够长
        require(signatures.length >= _threshold * 65, "DQ5006");

        // 通过一个循环，检查收集的签名是否有效
        // 大概思路：
        // 1. 用ecdsa先验证签名是否有效
        // 2. 利用 currentOwner > lastOwner 确定签名来自不同多签（多签地址递增）
        // 3. 利用 isOwner[currentOwner] 确定签名者为多签持有人
        address lastOwner = address(0); 
        address currentOwner;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 i;
        for (i = 0; i < _threshold; i++) {
            (v, r, s) = signatureSplit(signatures, i);
            // 利用ecrecover检查签名是否有效
            currentOwner = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)), v, r, s);
            require(currentOwner > lastOwner && isOwner[currentOwner], "DQ5007");
            lastOwner = currentOwner;
        }
    }

    /// 将单个签名从打包的签名分离出来
    /// @param signatures 打包签名
    /// @param pos 要读取的多签index.
    function signatureSplit(bytes memory signatures, uint256 pos)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        // 签名的格式：{bytes32 r}{bytes32 s}{uint8 v}
        assembly {
            let signaturePos := mul(0x41, pos)
            r := mload(add(signatures, add(signaturePos, 0x20)))
            s := mload(add(signatures, add(signaturePos, 0x40)))
            v := and(mload(add(signatures, add(signaturePos, 0x41))), 0xff)
        }
    }
}