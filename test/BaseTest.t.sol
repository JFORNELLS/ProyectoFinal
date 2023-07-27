// // SPDX-License-Identifier: UNLICENSED
// pragma solidity 0.8.10;

// import "forge-std/Test.sol";
// import {console} from "forge-std/console.sol";
// import {Utilities} from "./utils/Utilities.sol";

// contract BaseTest is Test {

//     struct Users {
//         address payable alice;
//         address payable bob;
//         address payable manolo;
//     }

//     Users public users;
//     Utilities internal utils;

//     function setUp() public virtual {
//         // setup utils
//         utils = new Utilities();

//         users = Users({
//             alice: utils.createUser("Alice", tokens),
//             bob: utils.createUser("Bob", tokens),
//             manolo: utils.createUser("Manolo", tokens)
//         });

//         vm.startPrank({msgSender: users.alice, txOrigin: users.alice});
//     }
    
    
// }