# 🌱 Project idea

You can find the project idea checking the pdf file at `assessment/WEB_3_.pdf`.

# 🚀 Development instructions

- Run `npm install` beforehand

To compile the smart contract:
`npx hardhat compile`

<br/>

To run tests:

`npx hardhat test`

# 🔎 Checking the solutions

1. You need to explain how this hashing function works, line by line
   You can find a detailed explanation of how the hashing function works in the comments of the [DropERC721Mock.sol contract](./contracts/DropERC721Mock.sol)

2. You need to translate this function in a JS format, performing the same, no web3 calls are allowed.
   The translated function in JS format can be found in the [main.js file](./main.js).
   You can also check the tests written to make sure the translate function works as expected in the [test/encryptDecrypt.js](./test/encryptDecrypt.js). Run `npx hardhat test` to run them.
