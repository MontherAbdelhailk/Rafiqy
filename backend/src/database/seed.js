'use strict';

/**
 * Database Seed Script
 * Inserts sample data for development/testing.
 * Usage: node src/database/seed.js
 */

require('dotenv').config();
const bcrypt = require('bcryptjs');
const { Pool } = require('pg');
const logger = require('../utils/logger');

async function seed() {
  const pool = new Pool({
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT, 10) || 5432,
    database: process.env.DB_NAME || 'rafiq_db',
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD,
  });

  const client = await pool.connect();

  try {
    logger.info('🌱 Seeding database...');

    const saltRounds = parseInt(process.env.BCRYPT_SALT_ROUNDS, 10) || 12;

    const users = [
      { // 
        full_name: 'Rafiqy',
        first_name: 'Rafiqy',
        last_name: '',
        username: 'Rafiqy',
        email: 'admin@rafiqy.com',
        password: 'Admin@123456',
        role: 'admin',
        phone_number: '+201090895795',
        profile_picture: '/uploads/admin_logo.svg',
      },
      {//2223000000000007    my consultation session
        full_name: 'Test User',
        first_name: 'Test',
        last_name: 'User',
        username: 'testuser',
        email: 'test@rafiq.app',
        password: 'Test@123456',
        role: 'user',
        phone_number: '+201011111111',
        profile_picture: '/uploads/default_user.png',
      },
    ];
// Past Session
    await client.query('BEGIN');

    const createdUsers = {};

    for (const user of users) {
      const password_hash = await bcrypt.hash(user.password, saltRounds);

      const res = await client.query(
        `INSERT INTO users (full_name, first_name, last_name, username, email, password_hash, is_verified, role, phone_number, profile_picture)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
         ON CONFLICT (username) DO UPDATE SET role = EXCLUDED.role, phone_number = EXCLUDED.phone_number, profile_picture = EXCLUDED.profile_picture
         RETURNING id`,
        [user.full_name, user.first_name, user.last_name, user.username, user.email, password_hash, true, user.role, user.phone_number, user.profile_picture]
      );
// confirm booking
      const userId = res.rows[0]?.id;
      createdUsers[user.username] = userId;

      logger.info(`  ✓ Seeded user: ${user.username} (${user.email})`);
    }

    const adminId = createdUsers['Rafiqy'];
    const userId = createdUsers['testuser'];

    if (adminId && userId) {
      // Seed a couple of posts from Admin
      const postRes = await client.query(
        `INSERT INTO posts (content, user_id)
         VALUES ($1, $2)
         RETURNING id`,
        ["Active listening is more than just hearing words. It's about understanding the emotion behind them. Try giving your child 100% undivided attention for just 10 minutes a day and see the difference!", adminId]
      );
      const postId = postRes.rows[0].id;
      logger.info('  ✓ Seeded post 1');

      await client.query(
        `INSERT INTO posts (content, user_id)
         VALUES ($1, $2)`,
         ["Consistent bedtime routines are key to a child's sense of security and emotional well-being. Start reading a book together 20 minutes before sleeping.", adminId]
      );
      logger.info('  ✓ Seeded post 2');

      // Seed love from User
      await client.query(
        `INSERT INTO post_loves (post_id, user_id)
         VALUES ($1, $2)
         ON CONFLICT DO NOTHING`,
         [postId, userId]
      );
      logger.info('  ✓ Seeded post love');

      // Seed a comment from User
      const commentRes = await client.query(
        `INSERT INTO comments (post_id, user_id, content)
         VALUES ($1, $2, $3)
         RETURNING id`,
         [postId, userId, "This is really helpful! Tried it tonight and it worked like a charm."]
      );
      const commentId = commentRes.rows[0].id;
      logger.info('  ✓ Seeded comment');

      // Seed a reply from Admin
      await client.query(
        `INSERT INTO comment_replies (comment_id, user_id, content)
         VALUES ($1, $2, $3)`,
         [commentId, adminId, "Wonderful to hear! Consistency is key."]
      );
      logger.info('  ✓ Seeded comment reply');

      // Seed Reels
      const reelRes1 = await client.query(
        `INSERT INTO reels (caption, video_url, user_id, duration, resolution, aspect_ratio)
         VALUES ($1, $2, $3, $4, $5, $6)
         RETURNING id`,
         ["Understanding your child's emotions is the foundation of positive parenting.", "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4", adminId, "00:15", "1280x720", "16:9"]
      );
      const reelId1 = reelRes1.rows[0].id;
      logger.info('  ✓ Seeded reel 1');

      await client.query(
        `INSERT INTO reels (caption, video_url, user_id, duration, resolution, aspect_ratio)
         VALUES ($1, $2, $3, $4, $5, $6)`,
         ["Top 3 parenting tips for toddlers: keep it simple, be consistent, offer choices.", "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4", adminId, "00:15", "1280x720", "16:9"]
      );
      logger.info('  ✓ Seeded reel 2');

      await client.query(
        `INSERT INTO reels (caption, video_url, user_id, duration, resolution, aspect_ratio)
         VALUES ($1, $2, $3, $4, $5, $6)`,
         ["Building confidence in teenagers requires active listening and respect.", "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4", adminId, "00:15", "1280x720", "16:9"]
      );
      logger.info('  ✓ Seeded reel 3');

      // Seed Reel Love
      await client.query(
        `INSERT INTO reel_loves (reel_id, user_id)
         VALUES ($1, $2)`,
         [reelId1, userId]
      );
      logger.info('  ✓ Seeded reel love');

      // Seed Reel Comment
      const reelCommentRes = await client.query(
        `INSERT INTO reel_comments (reel_id, user_id, content)
         VALUES ($1, $2, $3)
         RETURNING id`,
         [reelId1, userId, "This video is amazing! Thanks for sharing."]
      );
      const reelCommentId = reelCommentRes.rows[0].id;
      logger.info('  ✓ Seeded reel comment');

      // Seed Reel Comment Like
      await client.query(
        `INSERT INTO reel_comment_likes (comment_id, user_id)
         VALUES ($1, $2)`,
         [reelCommentId, adminId]
      );
      logger.info('  ✓ Seeded reel comment like');

      // Seed Reel Comment Reply
      await client.query(
        `INSERT INTO reel_comment_replies (comment_id, user_id, content)
         VALUES ($1, $2, $3)`,
         [reelCommentId, adminId, "Glad it helped! Feel free to ask any questions."]
      );
      logger.info('  ✓ Seeded reel comment reply');

      // Seed Video Categories
      const catRes1 = await client.query(
        `INSERT INTO video_categories (title, description, icon_name)
         VALUES ($1, $2, $3)
         RETURNING id`,
         ['Parenting', 'Guided milestones for every developmental phase.', 'child_care']
      );
      const parentCatId = catRes1.rows[0].id;

      const catRes2 = await client.query(
        `INSERT INTO video_categories (title, description, icon_name)
         VALUES ($1, $2, $3)
         RETURNING id`,
         ['Marital Relationships', 'Educational videos on navigating relationship challenges.', 'favorite']
      );
      const maritalCatId = catRes2.rows[0].id;

      const catRes3 = await client.query(
        `INSERT INTO video_categories (title, description, icon_name)
         VALUES ($1, $2, $3)
         RETURNING id`,
         ['Youth (21–30)', 'Focused on preparing young adults for marriage and family life.', 'people']
      );
      const youthCatId = catRes3.rows[0].id;
      logger.info('  ✓ Seeded video categories');

      // Seed Video Subcategories (Stages)
      // Parenting Stages
      const subRes1 = await client.query(
        `INSERT INTO video_subcategories (category_id, title, subtitle, description, age_range, image_path)
         VALUES ($1, $2, $3, $4, $5, $6) RETURNING id`,
         [parentCatId, 'Early Foundation', '', 'Focus on secure attachment and sensory development.', '0–3 YEARS', 'assets/images/0to3.png']
      );
      const earlyFoundationSubId = subRes1.rows[0].id;

      await client.query(
        `INSERT INTO video_subcategories (category_id, title, subtitle, description, age_range, image_path)
         VALUES ($1, $2, $3, $4, $5, $6)`,
         [parentCatId, 'Behavior Control', '', 'Establishing boundaries and fundamental social skills.', '3–6 YEARS', 'assets/images/3to6.png']
      );
      await client.query(
        `INSERT INTO video_subcategories (category_id, title, subtitle, description, age_range, image_path)
         VALUES ($1, $2, $3, $4, $5, $6)`,
         [parentCatId, 'Middle Childhood', '', 'Developing competence and school-age independence.', '6–9 YEARS', 'assets/images/6to12.png']
      );
      await client.query(
        `INSERT INTO video_subcategories (category_id, title, subtitle, description, age_range, image_path)
         VALUES ($1, $2, $3, $4, $5, $6)`,
         [parentCatId, 'Pre-Adolescence', '', 'Emotional changes and complex social structures.', '9–12 YEARS', 'assets/images/12to15.png']
      );
      await client.query(
        `INSERT INTO video_subcategories (category_id, title, subtitle, description, age_range, image_path)
         VALUES ($1, $2, $3, $4, $5, $6)`,
         [parentCatId, 'Early Adolescence', '', 'Identity formation and navigating peer pressure.', '12–15 YEARS', 'assets/images/12to15.png']
      );
      await client.query(
        `INSERT INTO video_subcategories (category_id, title, subtitle, description, age_range, image_path)
         VALUES ($1, $2, $3, $4, $5, $6)`,
         [parentCatId, 'Late Adolescence', '', 'Preparing for autonomy and future planning.', '15–18 YEARS', 'assets/images/15to18.png']
      );
      await client.query(
        `INSERT INTO video_subcategories (category_id, title, subtitle, description, age_range, image_path)
         VALUES ($1, $2, $3, $4, $5, $6)`,
         [parentCatId, 'Transition to Maturity', '', 'Bridging adolescence and independent adult life.', '18–21 YEARS', 'assets/images/18to21.png']
      );

      // Marital Relationships Stages
      const subMar1 = await client.query(
        `INSERT INTO video_subcategories (category_id, title, subtitle, description, age_range, image_path)
         VALUES ($1, $2, $3, $4, $5, $6) RETURNING id`,
         [maritalCatId, 'Before Divorce', 'Relationship Management', 'Strategies for resolving conflict and strengthening the marital bond.', '', 'assets/images/relation.png']
      );
      const beforeDivorceSubId = subMar1.rows[0].id;

      await client.query(
        `INSERT INTO video_subcategories (category_id, title, subtitle, description, age_range, image_path)
         VALUES ($1, $2, $3, $4, $5, $6)`,
         [maritalCatId, 'After Divorce', 'Recovery & Growth', 'Healing, co-parenting, and rebuilding a fulfilling life.', '', 'assets/images/sons.png']
      );
      const subMar3 = await client.query(
        `INSERT INTO video_subcategories (category_id, title, subtitle, description, age_range, image_path)
         VALUES ($1, $2, $3, $4, $5, $6) RETURNING id`,
         [maritalCatId, 'Youth (21–30)', 'Young Adults', 'Educational videos focused on preparing young adults for marriage, responsibility, and family life.', '21–30 YEARS', 'assets/images/family_pic.png']
      );
      const maritalYouthSubId = subMar3.rows[0].id;

      // Youth (21–30) Category Stages
      const subYouth1 = await client.query(
        `INSERT INTO video_subcategories (category_id, title, subtitle, description, age_range, image_path)
         VALUES ($1, $2, $3, $4, $5, $6) RETURNING id`,
         [youthCatId, 'Youth (21–30)', 'Young Adults', 'Preparing young adults emotionally and practically for marriage and parenthood.', '21–30 YEARS', 'assets/images/family_pic.png']
      );
      const youthSubId = subYouth1.rows[0].id;

      logger.info('  ✓ Seeded video subcategories (stages)');

      // Seed Videos
      const vidRes1 = await client.query(
        `INSERT INTO videos (title, description, video_url, thumbnail_url, duration, resolution, aspect_ratio, is_public, category_id, subcategory_id, tags)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11) RETURNING id`,
         [
           'Understanding Secure Attachment',
           'Learn how secure attachment is formed in early foundation years (0-3) and how it affects development.',
           'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
           'assets/images/0to3.png',
           '01:25',
           '1280x720',
           '16:9',
           true,
           parentCatId,
           earlyFoundationSubId,
           ['parenting', 'attachment', 'behavior']
         ]
      );
      const vidId1 = vidRes1.rows[0].id;
      logger.info('  ✓ Seeded video 1');

      await client.query(
        `INSERT INTO videos (title, description, video_url, thumbnail_url, duration, resolution, aspect_ratio, is_public, category_id, subcategory_id, tags)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)`,
         [
           'Conflict Resolution in Marriage',
           'Key communication strategies couples can use to resolve major conflicts before deciding on divorce.',
           'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
           'assets/images/relation.png',
           '05:48',
           '1280x720',
           '16:9',
           true,
           maritalCatId,
           beforeDivorceSubId,
           ['marriage', 'conflict', 'communication']
         ]
      );
      logger.info('  ✓ Seeded video 2');

      await client.query(
        `INSERT INTO videos (title, description, video_url, thumbnail_url, duration, resolution, aspect_ratio, is_public, category_id, subcategory_id, tags)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)`,
         [
           'Preparing for Marriage',
           'Valuable advice for young adults (21-30) who are preparing to transition into family life and responsibilities.',
           'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4',
           'assets/images/family_pic.png',
           '12:30',
           '1280x720',
           '16:9',
           true,
           youthCatId,
           youthSubId,
           ['marriage', 'youth', 'responsibility']
         ]
      );
      logger.info('  ✓ Seeded video 3');

      // Seed Video View
      await client.query(
        `INSERT INTO video_views (video_id, user_id) VALUES ($1, $2)`,
        [vidId1, userId]
      );
      await client.query(
        `UPDATE videos SET view_count = 1 WHERE id = $1`,
        [vidId1]
      );
      logger.info('  ✓ Seeded video view');

      // Seed Video Like
      await client.query(
        `INSERT INTO video_likes (video_id, user_id) VALUES ($1, $2)`,
        [vidId1, userId]
      );
      logger.info('  ✓ Seeded video like');
    }

    await client.query('COMMIT');
    logger.info('✅ Database seeded successfully!');
  } catch (error) {
    await client.query('ROLLBACK');
    logger.error('❌ Seeding failed:', error.message);
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

seed().catch((err) => {
  logger.error('Seed error:', err);
  process.exit(1);
});
