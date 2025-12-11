module routes.blog;

import vibe.vibe;

void getBlogPage(HTTPServerRequest req, HTTPServerResponse res)
{
    res.render!("blog.dt");
}


void getBlogPostPage(HTTPServerRequest req, HTTPServerResponse res)
{
    res.render!("blog_post.dt");
}



