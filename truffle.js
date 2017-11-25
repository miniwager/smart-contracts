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
			port: 6083,
			gas: 2800000,
			gasPrice: 22000000000,
			network_id: "*"
		}
	}
};
