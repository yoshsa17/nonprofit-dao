// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Constant {
    // addresses from anvil
    address[] public members = [
        0xEEa296A43DAbbA647A588cFEA80afAce851c11cb,
        0x9d4a8d88544c6B1b1c017D09391577647E6f10be,
        0x4b5A32aaFC5b0eb58dcB0831d13b71D9A851cADf,
        0x7F02B60E7FA719Ad53a089C9396F36Ee1e5eFDA4
        // 0x48F2E3E188f8692A87d279acdf578e138d7213e9,
        // 0xBcCe1356cbC515FF140D85FCd6426C9eE2602C95
        // 0xe878F16c18727c902d0Ea9cB74f548ed54e3A0fc,
        // 0xB05557ea59a8D1ED9e7bd426396D88CC1f78bF84,
        // 0xc2B956996CE4a4463Ba31C1beD3c8Fe0C6d33CA3,
        // 0x09E8B978F0FdB73C24b289738a440e507baa8000,
        // 0x37bFB1b74041a960681E8D4553DA49449E525eeb,
        // 0x417fbA282Cb1Dda6F341D54aE0A7A7Ec59f3aF29,
        // 0x319955FC56ff4c95535d6E1aeaBe3394311f7a04,
        // 0xa5dea85e2405C92dAC8840c3e8AAaC219D452011,
        // 0x71386a7575c9DdaC1851C581DeeA75C7f3EdD2Cb
    ];

    string initialDomain = "DOMAIN_1";
    string initialAdminDomain = "DOMAIN_1_ADMIN";
    address public GovernorAddress = 0xfcD845F311421eC7889b24DB36c62A8084518B9A;
    address public SBRTManagerAddress = 0xc481DA0144C847096B8C99152093C8D5ec3D1bfa;
    bytes32 constant DOMAIN_1_ID = keccak256("DOMAIN_1");
    bytes32 constant MAIN_DOMAIN_ID = bytes32(0x00);

    // proposal prams
    bytes4 FUNC_SELECTOR;
    address[] targets;
    uint256[] values;
    bytes[] calldatas;
    string description;
}
