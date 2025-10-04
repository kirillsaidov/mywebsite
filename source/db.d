module db;

import vibe.db.mongo.mongo : MongoClient, MongoDatabase, connectMongoDB;

/// Mongo URI
enum mongoURI = "mongodb://localhost:27017/";
enum mongoDBName = "mywebsite";

/// Mngo client
MongoClient client;

auto getCollection(in string name)
{
    if (!client) client = connectMongoDB(mongoURI);
    return client.getDatabase(mongoDBName)[name];
}

