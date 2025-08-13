# 🧵 Threads MCP Server - Production-Ready Integration

[![Docker](https://img.shields.io/docker/v/sergekostenchuk/threads-mcp)](https://hub.docker.com/r/sergekostenchuk/threads-mcp)
[![npm](https://img.shields.io/npm/v/threads-mcp)](https://www.npmjs.com/package/threads-mcp)
[![License](https://img.shields.io/github/license/sergekostenchuk/threads-mcp)](LICENSE)
[![Tests](https://img.shields.io/github/actions/workflow/status/sergekostenchuk/threads-mcp/release.yml)](https://github.com/sergekostenchuk/threads-mcp/actions)

Complete Model Context Protocol (MCP) server for Meta's Threads platform with OAuth authentication, media uploads, analytics, and enterprise features.

## ✨ Features

- **Full Threads API Coverage**: Posts, replies, media, insights, search
- **OAuth 2.0 Authentication**: Secure token management with refresh
- **Media Support**: Images, videos, carousels with automatic optimization
- **Analytics & Insights**: Detailed metrics and engagement tracking
- **Production Ready**: Docker, health checks, rate limiting, caching
- **Type Safe**: Full TypeScript support with complete type definitions

## 🚀 Quick Start

### One-Line Install

```bash
curl -sSL https://raw.githubusercontent.com/sergekostenchuk/threads-mcp/main/install.sh | bash
```

### NPM Install

```bash
npm install -g threads-mcp
```

### Docker Install

```bash
docker run -d \
  --name threads-mcp \
  -p 8766:8766 \
  -e THREADS_APP_ID=your_app_id \
  -e THREADS_APP_SECRET=your_app_secret \
  -v $(pwd)/data:/data \
  ghcr.io/sergekostenchuk/threads-mcp:latest
```

## 📋 Prerequisites

- Node.js 18+ or Docker
- Threads App from [Meta for Developers](https://developers.facebook.com/apps/)
- Business or Creator account on Threads
- Valid OAuth redirect URI

## 🔧 Configuration

### 1. Create Threads App

1. Go to [Meta for Developers](https://developers.facebook.com/apps/)
2. Create new app → Type: Business
3. Add Threads API product
4. Configure OAuth Settings:
   - Valid OAuth Redirect URIs: `http://localhost:3000/callback`
   - App Domains: `localhost`

### 2. Configure Environment

Copy `.env.example` to `.env`:

```bash
cp ~/.config/threads-mcp/.env.example ~/.config/threads-mcp/.env
```

Edit with your credentials:

```env
THREADS_APP_ID=your_app_id_here
THREADS_APP_SECRET=your_app_secret_here
OAUTH_REDIRECT_URI=http://localhost:3000/callback
```

### 3. OAuth Authentication

Run the OAuth helper to get access token:

```bash
threads-oauth
```

This will:
1. Start local OAuth server on port 3000
2. Open browser for Threads login
3. Save access token automatically

## 🎯 Usage

### Start MCP Server

```bash
# Native
threads-mcp

# Docker
docker-compose up -d

# With custom port
threads-mcp --port 9000
```

### Add to Claude Desktop

Edit `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "threads": {
      "type": "stdio",
      "command": "/Users/you/.local/bin/threads-mcp",
      "args": [],
      "env": {
        "THREADS_APP_ID": "your_app_id",
        "THREADS_APP_SECRET": "your_app_secret",
        "THREADS_ACCESS_TOKEN": "your_access_token"
      }
    }
  }
}
```

## 📚 Available Methods

### Content Publishing
- `create_text_post` - Create text-only post
- `create_image_post` - Post with single image
- `create_video_post` - Post with video
- `create_carousel_post` - Multiple images post
- `reply_to_post` - Reply to existing post
- `quote_post` - Quote another post
- `delete_post` - Delete your post

### Content Management
- `get_post` - Get post details
- `get_post_replies` - Get replies to a post
- `get_user_posts` - Get user's posts
- `get_conversation` - Full conversation thread
- `manage_reply` - Hide/unhide/delete replies

### Analytics & Insights
- `get_post_insights` - Views, likes, replies metrics
- `get_profile_insights` - Follower demographics
- `get_daily_performance` - Daily metrics
- `get_best_performing_posts` - Top content
- `get_engagement_metrics` - Detailed engagement

### User & Profile
- `get_profile` - Get profile information
- `get_follower_demographics` - Audience analysis
- `get_profile_views` - Profile view metrics
- `lookup_public_profile` - Search by username

[Full API Documentation →](https://github.com/sergekostenchuk/threads-mcp/wiki/API)

## 🐳 Docker Deployment

### docker-compose.yml

```yaml
version: '3.8'
services:
  threads-mcp:
    image: ghcr.io/sergekostenchuk/threads-mcp:latest
    restart: unless-stopped
    ports:
      - "8766:8766"
    volumes:
      - ./data:/data
      - ./logs:/logs
    env_file:
      - .env
```

### Run with Docker Compose

```bash
docker-compose up -d
docker-compose logs -f  # View logs
docker-compose down     # Stop
```

## 🔒 Security

- **OAuth 2.0**: Secure token-based authentication
- **Token Refresh**: Automatic token renewal
- **Rate Limiting**: Built-in API rate limit handling
- **Input Validation**: Joi schema validation
- **CORS Protection**: Configurable CORS policies
- **Helmet.js**: Security headers

## 📊 Monitoring

### Health Check

```bash
curl http://localhost:8766/health
```

Response:
```json
{
  "status": "healthy",
  "uptime": 3600,
  "connections": 5,
  "cache_size": 42
}
```

### Prometheus Metrics

Enable in `.env`:

```env
PROMETHEUS_ENABLED=true
PROMETHEUS_PORT=9090
```

### Logging

Structured logs with Winston:

```bash
tail -f logs/threads-mcp.log | jq '.'
```

## 📸 Media Upload

### Supported Formats

**Images**: JPEG, PNG, GIF, WebP (max 8MB)
**Videos**: MP4, MOV (max 100MB)

### Example: Upload Image

```javascript
// Automatic optimization and upload
await mcp.call('create_image_post', {
  imageUrl: 'https://example.com/image.jpg',
  text: 'Check out this photo!'
});
```

## 🔄 Updates

### Auto-update

```bash
threads-mcp update
```

### Manual Update

```bash
cd ~/.local/share/threads-mcp
git pull
npm install
```

## 🧪 Development

### Setup Development Environment

```bash
git clone https://github.com/sergekostenchuk/threads-mcp
cd threads-mcp
npm install
npm run dev
```

### Run Tests

```bash
npm test           # Run tests
npm run test:watch # Watch mode
npm run coverage   # Coverage report
```

### Code Quality

```bash
npm run lint       # ESLint
npm run format     # Prettier
npm run build      # TypeScript build
```

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing`)
5. Open Pull Request

## 📝 License

MIT License - see [LICENSE](LICENSE) file.

## 🔗 Resources

- [Threads API Documentation](https://developers.facebook.com/docs/threads)
- [MCP Protocol Spec](https://modelcontextprotocol.io/)
- [Meta for Developers](https://developers.facebook.com/)

## 💬 Support

- **Issues**: [GitHub Issues](https://github.com/sergekostenchuk/threads-mcp/issues)
- **Discussions**: [GitHub Discussions](https://github.com/sergekostenchuk/threads-mcp/discussions)
- **Email**: 9616166@gmail.com

## 🙏 Acknowledgments

- [Meta Threads Team](https://www.threads.net) - Platform API
- [Anthropic](https://anthropic.com) - MCP Protocol
- [Claude](https://claude.ai) - AI Assistant Platform

---

Made with ❤️ by Sergey Kostenchuk