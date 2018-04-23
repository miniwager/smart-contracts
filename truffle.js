module.exports = {
	networks: {
		development: {
			host: "94.130.35.43",
			port: 6082,
			gasPrice: 22000000000,
			address: "0x0d692765dece213f734a2b5562712ca4b1db81c9",
			network_id: "*" // Match any network id
		},
		live: {
			host: "localhost",
			address: "0xdefb0902a0c59657e0739a429166283a016ccda6",
			port: 6082,
			// gas: 4800000,
			// gasPrice: 22000000000,
			network_id: "*"
		}
	}
};
