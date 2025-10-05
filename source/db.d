module db;

import std.process : environment;
import vibe.db.mongo.mongo : MongoClient, MongoDatabase, connectMongoDB;

/// Mngo client
MongoClient client;

private
{
    string getMongoURI()
    {
        return environment.get("MONGO_URI", "mongodb://localhost:27017/");
    }

    string getMongoDefaultDB()
    {
        return environment.get("MONGO_DBNAME", "mywebsite");
    }
}

auto getCollection(in string name)
{
    if (!client) client = connectMongoDB(getMongoURI());
    return client.getDatabase(getMongoDefaultDB())[name];
}


