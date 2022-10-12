// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

// Mock DropERC721 that can be found here:
// https://github.com/thirdweb-dev/contracts/blob/main/contracts/drop/DropERC721.sol

contract DropERC721Mock {
    // The 'encryptDescrypt' function provides a solution to encrypt or decrypt the provided data on-chain

    // The function receives two parameters
    // - data -> dynamic array of bytes, stored in memory (in terms of data location)
    //           Although is more gas efficient to use calldata instead of memory location,
    //           direct access to calldata variable is not possible in assembly without copying it to other location,
    //           so that's why memory storage slots were used in this case.
    // - key -> dynamic array of bytes stored in the calldata location

    // The function is public, meaning that it can be called either from other methods of the contract/inherent contracts
    // or directly from outside the contract (from contracts or wallets addresses)

    // It is a pure function, which means it doesn't interract with the contract's state variables,
    // so there's no probability for it to be changed after calling this function

    // The function returns a dynamic bytes array, from the memory location having 'result' variable as reference
    // this variable is initialized and stored in memory before executing the function's block
    function encryptDecrypt(bytes memory data, bytes calldata key)
        public
        pure
        returns (bytes memory result)
    {
        // As presented in the comment below, this instruction initializez an uint256 variable ('length')
        // with the length of the 'data' bytes array and stores it to the EVM's stack

        // Store data length on stack for later
        uint256 length = data.length;

        // Open an inline assembly block where there's a contiguous memory sequence allocated for the 'result' array
        // Important to notice: the variables from the function's scope are accessible in the assembly block scope

        // solhint-disable-next-line no-inline-assembly
        assembly {
            // The block starts by setting 'result' as a reference to the first unused slot of memory (32 bytes 'word').
            // The reference to the first free memory slot is always stored at the 3rd memory slot of EVM (offset 0x40 and 0x50) which
            // is called the "free memory pointer". As value, the free memory ponter can have values starting from
            // 0x80, which is the first memory offset of the allocable memory area of the EVM.
            // Also, the initial value of the free memory pointer is 0x80.

            // Set result to free memory pointer
            result := mload(0x40)

            // After setting 'result' to the current free memory slot location,
            // the value at 0x40 should be updated to the next free 32 bytes sequence in the memory.
            // Because, in EVM, the memory acts like a contiguous unidimensional array, the next free memory word
            // is located at the index that's right after the memory slots occupied by the 'result' array.
            // To determine this position, we need to think about how a dynamic bytes array is stored in memory:
            // - first stored value (first 32 bytes) is the length of the array
            // - each value from the second item it's represented by each byte of the array.
            // Given the above, the new free memory pointer index is determined by the following formula - the calculated value is, then,stored at
            // 0x40 slot: 'result' (index of the current free memory pointer ) + 32(number of bytes needed to store the array length) + 'length'
            // This is translated in code to the 'add(add(result, length), 32)' sequence.

            // It's important to notice that
            // even if the array length is limited to the number represented by 'length' variable value, the number of bytes
            // that can be stored after the first memory slot (first 32 bytes) can be grater than 'length' value. This means that we don't have
            // the guarantee that the new free memory pointer value is 0.

            // Increase free memory pointer by lenght + 32
            mstore(0x40, add(add(result, length), 32))

            // The following line sets the 'result' array length
            // As we detailed above, the first 32 bytes slot occupied by dynamically sized arrays contain the array's length value

            // Set result length
            mstore(result, length)
        }

        // The following loop iterates over the provided 'data' array,
        // reading it in chunks of 32 bytes length
        // We can observe that 'i' variable, intialized with 0, is inceremented with 32.
        // 'i' value represents the starting byte index of the current processed 'word' in 'data' array

        // Iterate over the data stepping by 32 bytes
        for (uint256 i = 0; i < length; i += 32) {
            // The following instruction declares a 32 bytes variable called 'hash'
            // which contains the keccak256 hash of the non-standard (in-place) packed values of 'key' and 'i'.
            // abi.encodePacked(key, i) has the role to encode the concatenated hex values of 'key' and 'i':
            // and the returned (hex) value is: 0x + hex(key) + hex(i)
            // The value returned by abi.encodePacked(key, i) is a dynamically-sized bytes array.
            // This bytes sequence is hashed using the keccak256 hash function which returns
            // a 32 bytes value stored on EVM stack and having the 'hash' variable as a refrence.

            // Generate hash of the key and offset
            bytes32 hash = keccak256(abi.encodePacked(key, i));

            // Declare a 32 bytes 'chunk' variable and store it on stack.
            // Because this is not initialized when declared, its default value (in hex) would be
            // represented by the NullAddress (0x0000000000000000000000000000000000000000)
            // In terms of utility, the 'chunk' variable is declared here because it needs to be available
            // both in the for loop block scope (for next XOR operation) and also in the scopes of the two next inline assembly blocks
            bytes32 chunk;

            // Inline assembly block where chunk variable is assigned
            // solhint-disable-next-line no-inline-assembly
            assembly {
                // The following line assigns a sequence of 32 bytes from 'data' array to the 'chunk' variable
                // The assigned sequence value is the value stored at a memory slot of the 'data' array.
                // The position of the slot is calculated considering that the first 32 bytes at the 'data' array memory location
                // are used to store the array's length.
                // Given the above, using mload(add(data, add(i, 32))) means reading the following array chunk from memory: data[i+32]..data[i+64].

                // Read 32-bytes data chunk
                chunk := mload(add(data, add(i, 32)))
            }

            // The data 'chunk' is XORed with the previously-computed 'hash' value.
            // The obtained value is the data chunk's encrypted/decrypted value.
            // Both 'hash' and 'chunk' values are represented by 32-bytes length sequences, so the result is a value of 32 bytes,
            // stored on stack, at the slot already referenced by 'chunk'

            // XOR the chunk with hash
            chunk ^= hash;

            // The next inline assembly block stores the previously XORed 'chunk' value from stack to memory,
            // in the memory area reserved for the 'result' array.

            // solhint-disable-next-line no-inline-assembly
            assembly {
                // The following line updates the result array, storing the encrypted/decrypted 32 bytes sequence represented by 'chunk'.
                // The updated memory slot is calculated considering the first 32 bytes at the 'result' array location (which are used for length),
                // so the updated memory slot has the following coordinates, with respect to the 'result' array: result[i+32]..result[i+64]
                // Also, we can notice that the chunk's value is stored at the same position as the position it has been read from in 'data' array:
                // as effect result[i+32]..result[i+64] is the encrypted/decrypted value of data[i+32]..data[i+64]

                // Write 32-byte encrypted chunk
                mstore(add(result, add(i, 32)), chunk)
            }
        }

        // The function returns the 'result' value from memory
        // The length of the bytes array returned is determined by the 'data' array length
    }
}
