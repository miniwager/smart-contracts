module.exports = {
	networks: {
		development: {
			host: "localhost",
			port: 6083,
			gasPrice: 22000000000,
			network_id: "*" // Match any network id
		},
		live: {
			host: "localhost",
			address: "0xdefb0902a0c59657e0739a429166283a016ccda6",
			port: 6082,
			gas: 4800000,
			gasPrice: 22000000000,
			network_id: "*"
		}
	}
};
