const { ethers } = require("hardhat");
const { BigNumber } = ethers;

const encryptDecrypt = (data, key) => {
  const result = [];
  for (i = 0; i < data.length; i += 32) {
    const encodePacked = ethers.utils.solidityPack(["bytes", "uint256"], [key, i]);
    const hash = ethers.utils.solidityKeccak256(["bytes"], [encodePacked]);

    // get 32 bytes sequence as hex
    // add trailing zeros for the case when the bytes slice length is less than 32
    let chunk = ethers.utils.hexZeroPad(data.slice(i, i + 32));
    chunk += "0".repeat(hash.length - chunk.length);

    // XOR the chunk with hash
    chunk = BigNumber.from(chunk).xor(hash);

    // add chunk as hex value to the result array
    result.push(chunk.toHexString());
  }

  // return the bytes array represented as hex
  // conversion note: a byte is always represented by two hex digits
  // therefore, the slice length is 2 * data length (bytes array length)
  return (
    "0x" +
    result
      // remove starting '0x'
      .map((chunk) => chunk.slice(2))
      .join("")
      .slice(0, 2 * data.length)
  );
};

module.exports = {
  encryptDecrypt,
};
