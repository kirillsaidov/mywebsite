module db;

import std.process : environment;
import vibe.db.mongo.mongo : MongoClient, MongoDatabase, connectMongoDB;

@safe:

private
{
    /// Mongo client
    MongoClient client;

    string getMongoURI()
    {
        return environment.get("MONGO_URI", "mongodb://localhost:27017/");
    }

    string getMongoDefaultDB()
    {
        return environment.get("MONGO_DBNAME", "mywebsite");
    }
}

auto getMongoCollection(in string name)
{
    if (!client) client = connectMongoDB(getMongoURI());
    return client.getDatabase(getMongoDefaultDB())[name];
}


