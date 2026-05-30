parameters{
	df_filename as string,
	df_folder_path as string
}
source(output(
		transaction_id as short,
		transactional_date as timestamp,
		product_id as string,
		customer_id as short,
		payment as string,
		credit_card as long,
		loyalty_card as boolean,
		cost as double,
		quantity as short,
		price as double
	),
	allowSchemaDrift: true,
	validateSchema: false,
	ignoreNoFilesFound: false,
	wildcardPaths:[(concat('**/', $df_filename))]) ~> source1
source1 select(mapColumn(
		transaction_id,
		transactional_date,
		product_id,
		customer_id,
		payment,
		price
	),
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true) ~> select1
select1 filter(customer_id!=12) ~> filterCustomerID
filterCustomerID split(payment =="visa",
	payment =="mastercard",
	disjoint: false) ~> split1@(visa, masterCard, Amex)
split1@Amex derive(payment = coalesce(payment,'N/A')) ~> derivedColumn1
split1@visa aggregate(groupBy(customer_id),
	product_id = max(product_id)) ~> aggregate1
aggregate1 alterRow(insertIf(1==1)) ~> alterRow1
alterRow1 sink(allowSchemaDrift: true,
	validateSchema: false,
	umask: 0022,
	preCommands: [],
	postCommands: [],
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true) ~> sinkProductIDGroupeData