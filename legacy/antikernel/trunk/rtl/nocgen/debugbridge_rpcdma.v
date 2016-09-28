	JtagDebugController debug_controller (
		.clk_noc(clk_noc), 
		.rpc_tx_en(  root_rpc_rx_en), 
		.rpc_tx_data(root_rpc_rx_data), 
		.rpc_tx_ack( root_rpc_rx_ack), 
		.rpc_rx_en(  root_rpc_tx_en), 
		.rpc_rx_data(root_rpc_tx_data), 
		.rpc_rx_ack( root_rpc_tx_ack), 
		.dma_tx_en(  root_dma_rx_en), 
		.dma_tx_data(root_dma_rx_data), 
		.dma_tx_ack( root_dma_rx_ack), 
		.dma_rx_en(  root_dma_tx_en), 
		.dma_rx_data(root_dma_tx_data), 
		.dma_rx_ack( root_dma_tx_ack)
		);
