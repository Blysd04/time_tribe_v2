package repository

import (
	"context"
	"errors"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"

	"timetribe-backend/internal/models"
)

// Store giữ handle tới 11 collection, các service dùng chung một Store.
type Store struct {
	DB                   *mongo.Database
	Users                *mongo.Collection
	UserSecurities       *mongo.Collection
	UserTokens           *mongo.Collection
	Timeblocks           *mongo.Collection
	Templates            *mongo.Collection
	TemplateBlocks       *mongo.Collection
	Tribes               *mongo.Collection
	TribeAttendees       *mongo.Collection
	TribeBlocks          *mongo.Collection
	TribeBlockAttendance *mongo.Collection
	Notifications        *mongo.Collection
}

func NewStore(db *mongo.Database) *Store {
	return &Store{
		DB:                   db,
		Users:                db.Collection(models.CollUsers),
		UserSecurities:       db.Collection(models.CollUserSecurities),
		UserTokens:           db.Collection(models.CollUserTokens),
		Timeblocks:           db.Collection(models.CollTimeblocks),
		Templates:            db.Collection(models.CollTemplates),
		TemplateBlocks:       db.Collection(models.CollTemplateBlocks),
		Tribes:               db.Collection(models.CollTribes),
		TribeAttendees:       db.Collection(models.CollTribeAttendees),
		TribeBlocks:          db.Collection(models.CollTribeBlocks),
		TribeBlockAttendance: db.Collection(models.CollTribeBlockAttendance),
		Notifications:        db.Collection(models.CollNotifications),
	}
}

// FindOne trả về (nil, nil) khi không có bản ghi, cho service dễ kiểm tra.
func FindOne[T any](ctx context.Context, coll *mongo.Collection, filter any, opts ...options.Lister[options.FindOneOptions]) (*T, error) {
	var out T
	err := coll.FindOne(ctx, filter, opts...).Decode(&out)
	if errors.Is(err, mongo.ErrNoDocuments) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &out, nil
}

// FindMany luôn trả về slice khác nil để JSON ra [] thay vì null.
func FindMany[T any](ctx context.Context, coll *mongo.Collection, filter any, opts ...options.Lister[options.FindOptions]) ([]T, error) {
	cur, err := coll.Find(ctx, filter, opts...)
	if err != nil {
		return nil, err
	}
	out := make([]T, 0)
	if err := cur.All(ctx, &out); err != nil {
		return nil, err
	}
	return out, nil
}

func ByID(id string) bson.M { return bson.M{"_id": id} }

func In[T any](values []T) bson.M { return bson.M{"$in": values} }

func IsDuplicateKey(err error) bool { return mongo.IsDuplicateKeyError(err) }

// UsersByIDs lấy thông tin rút gọn của nhiều người cùng lúc, trả về map theo id.
func (s *Store) UsersByIDs(ctx context.Context, ids []string) (map[string]models.User, error) {
	out := map[string]models.User{}
	if len(ids) == 0 {
		return out, nil
	}
	users, err := FindMany[models.User](ctx, s.Users, bson.M{"_id": In(ids)})
	if err != nil {
		return nil, err
	}
	for _, u := range users {
		out[u.ID] = u
	}
	return out, nil
}

func (s *Store) UserByID(ctx context.Context, id string) (*models.User, error) {
	return FindOne[models.User](ctx, s.Users, ByID(id))
}

func (s *Store) SecurityByUserID(ctx context.Context, id string) (*models.UserSecurity, error) {
	return FindOne[models.UserSecurity](ctx, s.UserSecurities, ByID(id))
}
