package database

import (
	"context"
	"fmt"
	"log"
	"time"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"

	"timetribe-backend/internal/models"
)

// Connect mở kết nối tới MongoDB và ping thử để chắc chắn server đang chạy.
func Connect(uri, dbName string) (*mongo.Client, *mongo.Database, error) {
	client, err := mongo.Connect(options.Client().ApplyURI(uri))
	if err != nil {
		return nil, nil, err
	}
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := client.Ping(ctx, nil); err != nil {
		return nil, nil, fmt.Errorf("không ping được MongoDB tại %s: %w", uri, err)
	}
	return client, client.Database(dbName), nil
}

// EnsureIndexes tạo các index tương đương ràng buộc unique / khoá ngoại trong thiết kế CSDL.
// Chạy nhiều lần không sao, index đã có thì MongoDB bỏ qua.
func EnsureIndexes(db *mongo.Database) error {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	unique := func() *options.IndexOptionsBuilder { return options.Index().SetUnique(true) }
	// Chỉ ràng buộc unique khi cột có giá trị, vì nhiều bản ghi có thể cùng null
	uniqueIfString := func(field string) *options.IndexOptionsBuilder {
		return options.Index().SetUnique(true).
			SetPartialFilterExpression(bson.D{{Key: field, Value: bson.D{{Key: "$type", Value: "string"}}}})
	}

	plan := map[string][]mongo.IndexModel{
		models.CollUsers: {
			{Keys: bson.D{{Key: "email", Value: 1}}, Options: unique()},
			{Keys: bson.D{{Key: "nick_name", Value: 1}}, Options: unique()},
		},
		models.CollUserSecurities: {
			{Keys: bson.D{{Key: "google_id", Value: 1}}, Options: uniqueIfString("google_id")},
		},
		models.CollUserTokens: {
			{Keys: bson.D{{Key: "token", Value: 1}}, Options: unique()},
			{Keys: bson.D{{Key: "user_id", Value: 1}, {Key: "token_type", Value: 1}}},
			// Token hết hạn sẽ được MongoDB tự xoá
			{Keys: bson.D{{Key: "expires_at", Value: 1}}, Options: options.Index().SetExpireAfterSeconds(0)},
		},
		models.CollTimeblocks: {
			{Keys: bson.D{{Key: "user_id", Value: 1}, {Key: "date", Value: 1}}},
			{Keys: bson.D{{Key: "date", Value: 1}}},
		},
		models.CollTemplates: {
			{Keys: bson.D{{Key: "user_id", Value: 1}}},
			{Keys: bson.D{{Key: "share_token", Value: 1}}, Options: uniqueIfString("share_token")},
			{Keys: bson.D{{Key: "original_template_id", Value: 1}}},
		},
		models.CollTemplateBlocks: {
			{Keys: bson.D{{Key: "template_id", Value: 1}, {Key: "day_index", Value: 1}}},
		},
		models.CollTribes: {
			{Keys: bson.D{{Key: "invite_link", Value: 1}}, Options: unique()},
		},
		models.CollTribeAttendees: {
			{Keys: bson.D{{Key: "tribe_id", Value: 1}, {Key: "user_id", Value: 1}}, Options: unique()},
			{Keys: bson.D{{Key: "user_id", Value: 1}}},
		},
		models.CollTribeBlocks: {
			{Keys: bson.D{{Key: "tribe_id", Value: 1}, {Key: "date", Value: 1}}},
			{Keys: bson.D{{Key: "date", Value: 1}}},
		},
		models.CollTribeBlockAttendance: {
			{Keys: bson.D{{Key: "tribe_block_id", Value: 1}, {Key: "user_id", Value: 1}}, Options: unique()},
			{Keys: bson.D{{Key: "user_id", Value: 1}}},
		},
		models.CollNotifications: {
			{Keys: bson.D{{Key: "user_id", Value: 1}, {Key: "created_at", Value: -1}}},
		},
	}

	// Tạo từng index một, cái nào lỗi thì chỉ cảnh báo để server vẫn chạy được
	// (ví dụ một số bản MongoDB tương thích không hỗ trợ TTL index)
	failed := 0
	for coll, idx := range plan {
		for _, m := range idx {
			if _, err := db.Collection(coll).Indexes().CreateOne(ctx, m); err != nil {
				failed++
				log.Printf("cảnh báo: không tạo được index %v cho %s: %v", m.Keys, coll, err)
			}
		}
	}
	if failed == 0 {
		log.Println("đã kiểm tra index cho 11 collection")
	}
	return nil
}
