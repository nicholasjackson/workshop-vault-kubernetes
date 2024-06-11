print("Started Adding the Users.");
db = db.getSiblingDB("chat");
db.createUser({
  user: "chat",
  pwd: "password",
  roles: [{ role: "readWrite", db: "chat" }],
});
print("End Adding the User Roles.");