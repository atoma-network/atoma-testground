-- Create a function that will update the node's public address
CREATE
OR REPLACE FUNCTION update_node_address(node_ip text) RETURNS void AS $$ BEGIN
UPDATE
	nodes
SET
	public_address = 'http://' || node_ip || ':3000'
WHERE
	node_small_id = 1;

END;

$$ LANGUAGE plpgsql;

-- Create a function to initialize the database with required data
CREATE
OR REPLACE FUNCTION initialize_database(node_ip text, api_token text) RETURNS void AS $$ BEGIN PERFORM update_node_address(node_ip);

-- Insert initial API token if it doesn't exist
INSERT INTO
	api_tokens (user_id, token, name)
VALUES
	(1, api_token, 'chad');

-- Insert initial balance if it doesn't exist
INSERT INTO
	balance (user_id, usdc_balance)
VALUES
	(1, 10000000000000);

END;

$$ LANGUAGE plpgsql;

-- Note: The actual initialization will be called from the deployment script
-- with the appropriate parameters