// Module for testing coin administration functionalities
module nisarg::test_coins {
    // Importing necessary modules and types
    use std::string::utf8;
    use std::signer;

    use aptos_framework::coin::{Self, Coin, MintCapability, BurnCapability};

    // Structs representing custom coins
    struct LzUSDC {}
    struct LzUSDT {}

    // Struct to hold capabilities for minting and burning coins
    struct Capabilities<phantom CoinType> has key {
        mint_cap: MintCapability<CoinType>,
        burn_cap: BurnCapability<CoinType>,
    }

    // Function to initialize and register custom coins
    public entry fun register_coins(admin: &signer) {
        // Initialize and register LzUSDC coin
        let (lz_usdc_burn_cap,
            lz_usdc_freeze_cap,
            lz_usdc_mint_cap) =
            coin::initialize<LzUSDC>(
                admin,
                utf8(b"lzUSDC"),
                utf8(b"lzUSDC"),
                6,
                true,
            );
        // Initialize and register LzUSDT coin
        let (lz_usdt_burn_cap,
            lz_usdt_freeze_cap,
            lz_usdt_mint_cap) =
            coin::initialize<LzUSDT>(
                admin,
                utf8(b"lzUSDT"),
                utf8(b"lzUSDT"),
                6,
                true,
            );

        // Move capabilities to the admin account
        move_to(admin, Capabilities<LzUSDC> {
            mint_cap: lz_usdc_mint_cap,
            burn_cap: lz_usdc_burn_cap,
        });
        move_to(admin, Capabilities<LzUSDT> {
            mint_cap: lz_usdt_mint_cap,
            burn_cap: lz_usdt_burn_cap,
        });

        // Destroy unused freeze capabilities
        coin::destroy_freeze_cap(lz_usdc_freeze_cap);
        coin::destroy_freeze_cap(lz_usdt_freeze_cap);
    }

    // Function to mint new coins and deposit them into a user's account
    // When this function is called, pass the CoinType as: deployer_address::test_coins::LzUSDC on explorer
    // Suppose the Current Deployer Address is: 0x61aacd5442b12f53230ae83750f42b6220ac98b52ff8983b120a7b8bae4ed38a
    //Then T0/CoinType is:: 0x61aacd5442b12f53230ae83750f42b6220ac98b52ff8983b120a7b8bae4ed38a::test_coins::LzUSDC
    public entry fun mint_and_deposit<CoinType>(anyuser: &signer, amount: u64) acquires Capabilities {
        // Borrow global capabilities and mint new coins
        let caps = borrow_global<Capabilities<CoinType>>(@nisarg);
        let coins = coin::mint(amount, &caps.mint_cap);

        // Get user address and ensure registration if not already done
        let user_address = signer::address_of(anyuser);
        if (!coin::is_account_registered<CoinType>(user_address)) {
            coin::register<CoinType>(anyuser);
        };

        // Deposit minted coins into the user's account
        coin::deposit(user_address, coins);
    }

    //To Run Directly on Move CLI:: aptos move run --function-id 0x61aacd5442b12f53230ae83750f42b6220ac98b52ff8983b120a7b8bae4ed38a::test_coins::mint_and_deposit --type-args 0x61aacd5442b12f53230ae83750f42b6220ac98b52ff8983b120a7b8bae4ed38a::test_coins::LzUSDC --args u64:10

    //Arguments must always be pairs of <type>:<arg> e.g. bool:true
    // Function to mint new coins
    public fun mint<CoinType>(coin_admin: &signer, amount: u64): Coin<CoinType> acquires Capabilities {
        // Borrow global capabilities and mint new coins
        let caps = borrow_global<Capabilities<CoinType>>(signer::address_of(coin_admin));
        coin::mint(amount, &caps.mint_cap)
    }

    // Function to burn coins
    public fun burn<CoinType>(coin_admin: &signer, coins: Coin<CoinType>) acquires Capabilities {
        // Check if coins value is zero and destroy if so
        if (coin::value(&coins) == 0) {
            coin::destroy_zero(coins);
        } else {
            // Borrow global capabilities and burn coins
            let caps = borrow_global<Capabilities<CoinType>>(signer::address_of(coin_admin));
            coin::burn(coins, &caps.burn_cap);
        };
    }
}
