package services

import "go.mongodb.org/mongo-driver/v2/mongo/options"

func upsertOne() *options.UpdateOneOptionsBuilder {
	return options.UpdateOne().SetUpsert(true)
}
