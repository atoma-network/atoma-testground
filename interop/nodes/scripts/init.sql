-- Create a function that will update the node's public address
CREATE
OR REPLACE FUNCTION update_node_address(node_ip text) RETURNS void AS $ $ BEGIN
UPDATE
	nodes
SET
	public_address = 'http://' || node_ip || ':3000'
WHERE
	node_small_id = 1;

END;

$ $ LANGUAGE plpgsql;

-- Insert initial API token
INSERT INTO
	api_tokens (user_id, token, name)
VALUES
	(1, '3VByNX7b1SAEkLCQkJkIPnidBSUKX2w', 'chad') ON CONFLICT DO NOTHING;

-- Insert initial balance
INSERT INTO
	balance (user_id, usdc_balance)
VALUES
	(1, 100000000000) ON CONFLICT DO NOTHING;