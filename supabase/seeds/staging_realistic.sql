-- ==========================================================================
-- LiveLocal Staging Realistic Seed Dataset (Real Malaysian Places & Guides)
-- Idempotent seed script using fixed deterministic UUIDs and ON CONFLICT updates
-- ==========================================================================
BEGIN;

-- 1.1 SPOTS (Base records)

INSERT INTO public.spots (id, owner_id, current_revision_id, approved_revision_id, moderation_version, created_at)
VALUES ('00000000-0100-0000-0000-000000000001', NULL, NULL, NULL, 1, clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.spots (id, owner_id, current_revision_id, approved_revision_id, moderation_version, created_at)
VALUES ('00000000-0100-0000-0000-000000000002', NULL, NULL, NULL, 1, clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.spots (id, owner_id, current_revision_id, approved_revision_id, moderation_version, created_at)
VALUES ('00000000-0100-0000-0000-000000000003', NULL, NULL, NULL, 1, clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.spots (id, owner_id, current_revision_id, approved_revision_id, moderation_version, created_at)
VALUES ('00000000-0100-0000-0000-000000000004', NULL, NULL, NULL, 1, clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.spots (id, owner_id, current_revision_id, approved_revision_id, moderation_version, created_at)
VALUES ('00000000-0100-0000-0000-000000000005', NULL, NULL, NULL, 1, clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.spots (id, owner_id, current_revision_id, approved_revision_id, moderation_version, created_at)
VALUES ('00000000-0100-0000-0000-000000000006', NULL, NULL, NULL, 1, clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.spots (id, owner_id, current_revision_id, approved_revision_id, moderation_version, created_at)
VALUES ('00000000-0100-0000-0000-000000000007', NULL, NULL, NULL, 1, clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.spots (id, owner_id, current_revision_id, approved_revision_id, moderation_version, created_at)
VALUES ('00000000-0100-0000-0000-000000000008', NULL, NULL, NULL, 1, clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.spots (id, owner_id, current_revision_id, approved_revision_id, moderation_version, created_at)
VALUES ('00000000-0100-0000-0000-000000000009', NULL, NULL, NULL, 1, clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.spots (id, owner_id, current_revision_id, approved_revision_id, moderation_version, created_at)
VALUES ('00000000-0100-0000-0000-00000000000a', NULL, NULL, NULL, 1, clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.spots (id, owner_id, current_revision_id, approved_revision_id, moderation_version, created_at)
VALUES ('00000000-0100-0000-0000-00000000000b', NULL, NULL, NULL, 1, clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.spots (id, owner_id, current_revision_id, approved_revision_id, moderation_version, created_at)
VALUES ('00000000-0100-0000-0000-00000000000c', NULL, NULL, NULL, 1, clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.spots (id, owner_id, current_revision_id, approved_revision_id, moderation_version, created_at)
VALUES ('00000000-0100-0000-0000-00000000000d', NULL, NULL, NULL, 1, clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.spots (id, owner_id, current_revision_id, approved_revision_id, moderation_version, created_at)
VALUES ('00000000-0100-0000-0000-00000000000e', NULL, NULL, NULL, 1, clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.spots (id, owner_id, current_revision_id, approved_revision_id, moderation_version, created_at)
VALUES ('00000000-0100-0000-0000-00000000000f', NULL, NULL, NULL, 1, clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.spots (id, owner_id, current_revision_id, approved_revision_id, moderation_version, created_at)
VALUES ('00000000-0100-0000-0000-000000000010', NULL, NULL, NULL, 1, clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.spots (id, owner_id, current_revision_id, approved_revision_id, moderation_version, created_at)
VALUES ('00000000-0100-0000-0000-000000000011', NULL, NULL, NULL, 1, clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.spots (id, owner_id, current_revision_id, approved_revision_id, moderation_version, created_at)
VALUES ('00000000-0100-0000-0000-000000000012', NULL, NULL, NULL, 1, clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.spots (id, owner_id, current_revision_id, approved_revision_id, moderation_version, created_at)
VALUES ('00000000-0100-0000-0000-000000000013', NULL, NULL, NULL, 1, clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.spots (id, owner_id, current_revision_id, approved_revision_id, moderation_version, created_at)
VALUES ('00000000-0100-0000-0000-000000000014', NULL, NULL, NULL, 1, clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.spots (id, owner_id, current_revision_id, approved_revision_id, moderation_version, created_at)
VALUES ('00000000-0100-0000-0000-000000000015', NULL, NULL, NULL, 1, clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.spots (id, owner_id, current_revision_id, approved_revision_id, moderation_version, created_at)
VALUES ('00000000-0100-0000-0000-000000000016', NULL, NULL, NULL, 1, clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.spots (id, owner_id, current_revision_id, approved_revision_id, moderation_version, created_at)
VALUES ('00000000-0100-0000-0000-000000000017', NULL, NULL, NULL, 1, clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.spots (id, owner_id, current_revision_id, approved_revision_id, moderation_version, created_at)
VALUES ('00000000-0100-0000-0000-000000000018', NULL, NULL, NULL, 1, clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.spots (id, owner_id, current_revision_id, approved_revision_id, moderation_version, created_at)
VALUES ('00000000-0100-0000-0000-000000000019', NULL, NULL, NULL, 1, clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.spots (id, owner_id, current_revision_id, approved_revision_id, moderation_version, created_at)
VALUES ('00000000-0100-0000-0000-00000000001a', NULL, NULL, NULL, 1, clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.spots (id, owner_id, current_revision_id, approved_revision_id, moderation_version, created_at)
VALUES ('00000000-0100-0000-0000-00000000001b', NULL, NULL, NULL, 1, clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.spots (id, owner_id, current_revision_id, approved_revision_id, moderation_version, created_at)
VALUES ('00000000-0100-0000-0000-00000000001c', NULL, NULL, NULL, 1, clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.spots (id, owner_id, current_revision_id, approved_revision_id, moderation_version, created_at)
VALUES ('00000000-0100-0000-0000-00000000001d', NULL, NULL, NULL, 1, clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.spots (id, owner_id, current_revision_id, approved_revision_id, moderation_version, created_at)
VALUES ('00000000-0100-0000-0000-00000000001e', NULL, NULL, NULL, 1, clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.spots (id, owner_id, current_revision_id, approved_revision_id, moderation_version, created_at)
VALUES ('00000000-0100-0000-0000-00000000001f', NULL, NULL, NULL, 1, clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.spots (id, owner_id, current_revision_id, approved_revision_id, moderation_version, created_at)
VALUES ('00000000-0100-0000-0000-000000000020', NULL, NULL, NULL, 1, clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.spots (id, owner_id, current_revision_id, approved_revision_id, moderation_version, created_at)
VALUES ('00000000-0100-0000-0000-000000000021', NULL, NULL, NULL, 1, clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.spots (id, owner_id, current_revision_id, approved_revision_id, moderation_version, created_at)
VALUES ('00000000-0100-0000-0000-000000000022', NULL, NULL, NULL, 1, clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.spots (id, owner_id, current_revision_id, approved_revision_id, moderation_version, created_at)
VALUES ('00000000-0100-0000-0000-000000000023', NULL, NULL, NULL, 1, clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.spots (id, owner_id, current_revision_id, approved_revision_id, moderation_version, created_at)
VALUES ('00000000-0100-0000-0000-000000000024', NULL, NULL, NULL, 1, clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.spots (id, owner_id, current_revision_id, approved_revision_id, moderation_version, created_at)
VALUES ('00000000-0100-0000-0000-000000000025', NULL, NULL, NULL, 1, clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


-- 1.2 SPOT REVISIONS

INSERT INTO public.spot_revisions (
  id, spot_id, revision_number, author_id, status, name, category, description,
  state, city, address, price_range, best_time, things_to_do, image_path,
  latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0110-0000-0000-000000000001', '00000000-0100-0000-0000-000000000001', 1, NULL, 'approved', 'Batu Caves', 'Culture', 'Iconic limestone caves and Hindu shrine with 272 colorful steps and towering Lord Murugan statue.',
  'Selangor', 'Gombak', 'Gombak, 68100 Batu Caves, Selangor', '$', 'Early morning (7:00 AM - 9:00 AM)', 'Climb the 272 steps, visit Temple Cave, explore Dark Cave conservation tour', NULL,
  3.2379, 101.684, clock_timestamp() - interval '39 days', clock_timestamp() - interval '38 days',
  clock_timestamp() - interval '39 days', clock_timestamp() - interval '38 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, status = EXCLUDED.status;


INSERT INTO public.spot_revisions (
  id, spot_id, revision_number, author_id, status, name, category, description,
  state, city, address, price_range, best_time, things_to_do, image_path,
  latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0110-0000-0000-000000000002', '00000000-0100-0000-0000-000000000002', 1, NULL, 'approved', 'Petronas Twin Towers & KLCC Park', 'Landmark', 'World''s tallest twin structures offering city views and a landscaped 50-acre tropical park.',
  'Kuala Lumpur', 'Kuala Lumpur', 'Concourse Level, Petronas Twin Tower, Lower Ground, KLCC, 50088 Kuala Lumpur', '$$', 'Evening / Sunset (5:30 PM - 8:00 PM)', 'Walk the Skybridge, photograph the Lake Symphony water fountain show, jog in KLCC Park', NULL,
  3.1579, 101.7116, clock_timestamp() - interval '38 days', clock_timestamp() - interval '37 days',
  clock_timestamp() - interval '38 days', clock_timestamp() - interval '37 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, status = EXCLUDED.status;


INSERT INTO public.spot_revisions (
  id, spot_id, revision_number, author_id, status, name, category, description,
  state, city, address, price_range, best_time, things_to_do, image_path,
  latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0110-0000-0000-000000000003', '00000000-0100-0000-0000-000000000003', 1, NULL, 'approved', 'Thean Hou Temple', 'Culture', 'Six-tiered Chinese temple combining Buddhism, Taoism, and Confucianism with panoramic KL skyline views.',
  'Kuala Lumpur', 'Kuala Lumpur', '65, Persiaran Endah, Taman Persiaran Desa, 50460 Kuala Lumpur', '$', 'Morning or late afternoon', 'Admire traditional architecture, view lanterns, enjoy city panoramas from top tier', NULL,
  3.1219, 101.6869, clock_timestamp() - interval '37 days', clock_timestamp() - interval '36 days',
  clock_timestamp() - interval '37 days', clock_timestamp() - interval '36 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, status = EXCLUDED.status;


INSERT INTO public.spot_revisions (
  id, spot_id, revision_number, author_id, status, name, category, description,
  state, city, address, price_range, best_time, things_to_do, image_path,
  latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0110-0000-0000-000000000004', '00000000-0100-0000-0000-000000000004', 1, NULL, 'approved', 'KL Forest Eco Park', 'Nature', 'One of the oldest permanent forest reserves in Malaysia with a lush canopy walk in the city center.',
  'Kuala Lumpur', 'Kuala Lumpur', 'Lot 240, Jalan Raja Chulan, Bukit Kewangan, 50250 Kuala Lumpur', '$', 'Morning (8:00 AM - 10:30 AM)', 'Trek canopy walk bridges, discover tropical rainforest flora and fauna', NULL,
  3.1504, 101.7018, clock_timestamp() - interval '36 days', clock_timestamp() - interval '35 days',
  clock_timestamp() - interval '36 days', clock_timestamp() - interval '35 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, status = EXCLUDED.status;


INSERT INTO public.spot_revisions (
  id, spot_id, revision_number, author_id, status, name, category, description,
  state, city, address, price_range, best_time, things_to_do, image_path,
  latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0110-0000-0000-000000000005', '00000000-0100-0000-0000-000000000005', 1, NULL, 'approved', 'Kek Lok Si Temple', 'Culture', 'Sprawling Buddhist temple complex featuring the 7-tier Pagoda of Rama VI and bronze Guanyin statue.',
  'Pulau Pinang', 'Air Itam', '1000-L, Tingkat Lembah Ria 1, 11500 Ayer Itam, Pulau Pinang', '$', 'Morning (8:30 AM - 11:00 AM)', 'Climb the Pagoda of 10,000 Buddhas, ride the inclined lift to Guanyin Pavilion, buy prayer ribbons', NULL,
  5.3995, 100.2736, clock_timestamp() - interval '35 days', clock_timestamp() - interval '34 days',
  clock_timestamp() - interval '35 days', clock_timestamp() - interval '34 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, status = EXCLUDED.status;


INSERT INTO public.spot_revisions (
  id, spot_id, revision_number, author_id, status, name, category, description,
  state, city, address, price_range, best_time, things_to_do, image_path,
  latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0110-0000-0000-000000000006', '00000000-0100-0000-0000-000000000006', 1, NULL, 'approved', 'Penang Hill (Bukit Bendera)', 'Nature', 'Cool hill resort accessible via historic funicular railway with rainforest walks and heritage bungalows.',
  'Pulau Pinang', 'Air Itam', 'Jalan Stesen Bukit Bendera, 11500 Air Itam, Penang', '$$', 'Early morning or late afternoon', 'Ride funicular railway, walk The Habitat Curtis Crest treetop walk, visit heritage post office', NULL,
  5.4242, 100.269, clock_timestamp() - interval '34 days', clock_timestamp() - interval '33 days',
  clock_timestamp() - interval '34 days', clock_timestamp() - interval '33 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, status = EXCLUDED.status;


INSERT INTO public.spot_revisions (
  id, spot_id, revision_number, author_id, status, name, category, description,
  state, city, address, price_range, best_time, things_to_do, image_path,
  latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0110-0000-0000-000000000007', '00000000-0100-0000-0000-000000000007', 1, NULL, 'approved', 'Cheong Fatt Tze - The Blue Mansion', 'Heritage', 'Restored 19th-century courtyard mansion famous for its indigo-blue exterior and Feng Shui architecture.',
  'Pulau Pinang', 'George Town', '14, Leith St, George Town, 10200 George Town, Pulau Pinang', '$$', 'Guided tour slots (11:00 AM / 2:00 PM)', 'Join guided architectural heritage tour, enjoy courtyard refreshments', NULL,
  5.4206, 100.3344, clock_timestamp() - interval '33 days', clock_timestamp() - interval '32 days',
  clock_timestamp() - interval '33 days', clock_timestamp() - interval '32 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, status = EXCLUDED.status;


INSERT INTO public.spot_revisions (
  id, spot_id, revision_number, author_id, status, name, category, description,
  state, city, address, price_range, best_time, things_to_do, image_path,
  latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0110-0000-0000-000000000008', '00000000-0100-0000-0000-000000000008', 1, NULL, 'approved', 'Pinang Peranakan Mansion', 'Heritage', 'Opulent museum displaying Straits Chinese Peranakan antiques, gold jewelry, and Baba-Nyonya lifestyle.',
  'Pulau Pinang', 'George Town', '29, Church St, George Town, 10200 George Town, Pulau Pinang', '$$', 'Morning to afternoon (9:30 AM - 4:00 PM)', 'Explore restored Peranakan rooms, view vintage jewellery and antique ceramics', NULL,
  5.4182, 100.3409, clock_timestamp() - interval '32 days', clock_timestamp() - interval '31 days',
  clock_timestamp() - interval '32 days', clock_timestamp() - interval '31 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, status = EXCLUDED.status;


INSERT INTO public.spot_revisions (
  id, spot_id, revision_number, author_id, status, name, category, description,
  state, city, address, price_range, best_time, things_to_do, image_path,
  latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0110-0000-0000-000000000009', '00000000-0100-0000-0000-000000000009', 1, NULL, 'approved', 'A Famosa (Porta de Santiago)', 'Historical', 'Historic 16th-century Portuguese fortress gate standing as one of Southeast Asia''s oldest European architectural remains.',
  'Melaka', 'Melaka', 'Jalan Kota, Bandar Hilir, 75000 Melaka', '$', 'Morning or sunset', 'Photograph historic stone gate, read historical markers, walk up to St. Paul''s Hill', NULL,
  2.192, 102.2494, clock_timestamp() - interval '31 days', clock_timestamp() - interval '30 days',
  clock_timestamp() - interval '31 days', clock_timestamp() - interval '30 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, status = EXCLUDED.status;


INSERT INTO public.spot_revisions (
  id, spot_id, revision_number, author_id, status, name, category, description,
  state, city, address, price_range, best_time, things_to_do, image_path,
  latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0110-0000-0000-00000000000a', '00000000-0100-0000-0000-00000000000a', 1, NULL, 'approved', 'St. Paul''s Hill & Church', 'Historical', 'Ruined 1521 Portuguese church with historic Dutch tombstones and scenic vistas of Melaka Straits.',
  'Melaka', 'Melaka', 'Jalan Kota, Bandar Hilir, 75000 Melaka', '$', 'Late afternoon / Sunset', 'View historic tombstones, statue of St. Francis Xavier, watch sunset over the Straits', NULL,
  2.1928, 102.2492, clock_timestamp() - interval '30 days', clock_timestamp() - interval '29 days',
  clock_timestamp() - interval '30 days', clock_timestamp() - interval '29 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, status = EXCLUDED.status;


INSERT INTO public.spot_revisions (
  id, spot_id, revision_number, author_id, status, name, category, description,
  state, city, address, price_range, best_time, things_to_do, image_path,
  latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0110-0000-0000-00000000000b', '00000000-0100-0000-0000-00000000000b', 1, NULL, 'approved', 'Jonker Street Night Market', 'Culture', 'Bustling weekend street market filled with local street food, antique crafts, and cultural performances.',
  'Melaka', 'Melaka', 'Jalan Hang Jebat, 75200 Melaka', '$', 'Friday - Sunday evenings (6:00 PM - 11:00 PM)', 'Sample local snacks, browse craft stalls, watch stage performances at Jonker Walk stage', NULL,
  2.1956, 102.2476, clock_timestamp() - interval '29 days', clock_timestamp() - interval '28 days',
  clock_timestamp() - interval '29 days', clock_timestamp() - interval '28 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, status = EXCLUDED.status;


INSERT INTO public.spot_revisions (
  id, spot_id, revision_number, author_id, status, name, category, description,
  state, city, address, price_range, best_time, things_to_do, image_path,
  latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0110-0000-0000-00000000000c', '00000000-0100-0000-0000-00000000000c', 1, NULL, 'approved', 'Baba & Nyonya Heritage Museum', 'Heritage', 'Preserved ancestral townhouse offering guided insights into rich Peranakan culture and traditions.',
  'Melaka', 'Melaka', '48-50, Jalan Tun Tan Cheng Lock, 75200 Melaka', '$$', 'Morning (10:00 AM - 1:00 PM)', 'Take guided museum tour, learn about Peranakan customs, observe historic courtyard architecture', NULL,
  2.1952, 102.2464, clock_timestamp() - interval '28 days', clock_timestamp() - interval '27 days',
  clock_timestamp() - interval '28 days', clock_timestamp() - interval '27 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, status = EXCLUDED.status;


INSERT INTO public.spot_revisions (
  id, spot_id, revision_number, author_id, status, name, category, description,
  state, city, address, price_range, best_time, things_to_do, image_path,
  latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0110-0000-0000-00000000000d', '00000000-0100-0000-0000-00000000000d', 1, NULL, 'approved', 'Kellie''s Castle', 'Historical', 'Unfinished Scottish mansion built in 1915 with hidden rooms, secret underground tunnels, and rooftop views.',
  'Perak', 'Batu Gajah', 'Lot 48436, Kompleks Pelancongan Kellie''s Castle, KM 5.5, Jalan Gopeng, 31000 Batu Gajah, Perak', '$', 'Morning or late afternoon', 'Explore hidden wine cellar and elevator shaft, photograph Gothic-Greco-Roman architecture', NULL,
  4.4754, 101.0877, clock_timestamp() - interval '27 days', clock_timestamp() - interval '26 days',
  clock_timestamp() - interval '27 days', clock_timestamp() - interval '26 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, status = EXCLUDED.status;


INSERT INTO public.spot_revisions (
  id, spot_id, revision_number, author_id, status, name, category, description,
  state, city, address, price_range, best_time, things_to_do, image_path,
  latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0110-0000-0000-00000000000e', '00000000-0100-0000-0000-00000000000e', 1, NULL, 'approved', 'Perak Cave Temple (Perak Tong)', 'Culture', 'Limestone cave temple housing a 40-foot sitting Buddha and vibrant traditional murals with a panoramic summit climb.',
  'Perak', 'Ipoh', 'Jalan Kuala Kangsar, Kawasan Perindustrian Tasek, 31400 Ipoh, Perak', '$', 'Morning (9:00 AM - 12:00 PM)', 'Admire cave murals and giant Buddha, climb stairs to panoramic summit lookout', NULL,
  4.6469, 101.0991, clock_timestamp() - interval '26 days', clock_timestamp() - interval '25 days',
  clock_timestamp() - interval '26 days', clock_timestamp() - interval '25 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, status = EXCLUDED.status;


INSERT INTO public.spot_revisions (
  id, spot_id, revision_number, author_id, status, name, category, description,
  state, city, address, price_range, best_time, things_to_do, image_path,
  latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0110-0000-0000-00000000000f', '00000000-0100-0000-0000-00000000000f', 1, NULL, 'approved', 'Concubine Lane (Panglima Lane)', 'Heritage', 'Heritage alley in Ipoh Old Town bustling with artisanal cafes, souvenir stalls, and colonial shophouses.',
  'Perak', 'Ipoh', 'Panglima Ln, 30000 Ipoh, Perak', '$', 'Morning to late afternoon (10:00 AM - 4:00 PM)', 'Stroll historical lane, sample rain-drop cake and tofu pudding, take street art photos', NULL,
  4.5969, 101.0783, clock_timestamp() - interval '25 days', clock_timestamp() - interval '24 days',
  clock_timestamp() - interval '25 days', clock_timestamp() - interval '24 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, status = EXCLUDED.status;


INSERT INTO public.spot_revisions (
  id, spot_id, revision_number, author_id, status, name, category, description,
  state, city, address, price_range, best_time, things_to_do, image_path,
  latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0110-0000-0000-000000000010', '00000000-0100-0000-0000-000000000010', 1, NULL, 'approved', 'Tempurung Cave (Gua Tempurung)', 'Nature', 'Massive show cave system stretching over 3 km with impressive stalactites, stalagmites, and subterranean stream walks.',
  'Perak', 'Gopeng', 'Pusat Pelancongan Gua Tempurung, 31600 Gopeng, Perak', '$$', 'Morning (9:00 AM - 1:00 PM)', 'Choose guided dry or wet caving adventure, view Golden Flowstone chamber', NULL,
  4.4172, 101.1878, clock_timestamp() - interval '24 days', clock_timestamp() - interval '23 days',
  clock_timestamp() - interval '24 days', clock_timestamp() - interval '23 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, status = EXCLUDED.status;


INSERT INTO public.spot_revisions (
  id, spot_id, revision_number, author_id, status, name, category, description,
  state, city, address, price_range, best_time, things_to_do, image_path,
  latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0110-0000-0000-000000000011', '00000000-0100-0000-0000-000000000011', 1, NULL, 'approved', 'Sultan Abu Bakar State Mosque', 'Architecture', '19th-century Victorian and Moorish-inspired royal mosque overlooking the Straits of Johor.',
  'Johor', 'Johor Bahru', 'Jalan Skudai, Bandar Johor Bahru, 80000 Johor Bahru, Johor', '$', 'Morning (outside prayer times)', 'Appreciate Victorian-Moorish architectural details, enjoy scenic views of the straits', NULL,
  1.458, 103.7554, clock_timestamp() - interval '23 days', clock_timestamp() - interval '22 days',
  clock_timestamp() - interval '23 days', clock_timestamp() - interval '22 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, status = EXCLUDED.status;


INSERT INTO public.spot_revisions (
  id, spot_id, revision_number, author_id, status, name, category, description,
  state, city, address, price_range, best_time, things_to_do, image_path,
  latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0110-0000-0000-000000000012', '00000000-0100-0000-0000-000000000012', 1, NULL, 'approved', 'Tan Hiok Nee Heritage Walk', 'Heritage', 'Historic cultural street in Johor Bahru honoring early Chinese pioneer heritage, with bakeries and cafes.',
  'Johor', 'Johor Bahru', 'Jalan Tan Hiok Nee, Bandar Johor Bahru, 80000 Johor Bahru, Johor', '$', 'Morning to afternoon', 'Taste wood-fired banana cakes, visit heritage kopitiams, admire street murals', NULL,
  1.4568, 103.7645, clock_timestamp() - interval '22 days', clock_timestamp() - interval '21 days',
  clock_timestamp() - interval '22 days', clock_timestamp() - interval '21 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, status = EXCLUDED.status;


INSERT INTO public.spot_revisions (
  id, spot_id, revision_number, author_id, status, name, category, description,
  state, city, address, price_range, best_time, things_to_do, image_path,
  latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0110-0000-0000-000000000013', '00000000-0100-0000-0000-000000000013', 1, NULL, 'approved', 'Desaru Coast & Beach', 'Nature', 'Pristine 17 km coastline offering golden sand beaches, coastal water sports, and relaxed family recreation.',
  'Johor', 'Bandar Penawar', 'Bandar Penawar, 81930 Kota Tinggi, Johor', '$', 'Sunrise or late afternoon', 'Relax on public beach, participate in water sports, explore coastal walking trails', NULL,
  1.5544, 104.2582, clock_timestamp() - interval '21 days', clock_timestamp() - interval '20 days',
  clock_timestamp() - interval '21 days', clock_timestamp() - interval '20 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, status = EXCLUDED.status;


INSERT INTO public.spot_revisions (
  id, spot_id, revision_number, author_id, status, name, category, description,
  state, city, address, price_range, best_time, things_to_do, image_path,
  latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0110-0000-0000-000000000014', '00000000-0100-0000-0000-000000000014', 1, NULL, 'approved', 'Tanjung Piai National Park', 'Nature', 'Southernmost tip of mainland Asia with mangrove boardwalks, mudskippers, and international shipping lane views.',
  'Johor', 'Pontian', 'Mukim Serkat, 82030 Pontian, Johor', '$', 'Morning or late afternoon', 'Stand at the Southernmost Tip globe monument, walk mangrove boardwalks, spot migratory birds', NULL,
  1.2662, 103.51, clock_timestamp() - interval '20 days', clock_timestamp() - interval '19 days',
  clock_timestamp() - interval '20 days', clock_timestamp() - interval '19 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, status = EXCLUDED.status;


INSERT INTO public.spot_revisions (
  id, spot_id, revision_number, author_id, status, name, category, description,
  state, city, address, price_range, best_time, things_to_do, image_path,
  latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0110-0000-0000-000000000015', '00000000-0100-0000-0000-000000000015', 1, NULL, 'approved', 'Kinabalu Park & Mount Kinabalu', 'Nature', 'UNESCO World Heritage Site with hyper-diverse mountain flora, botanical gardens, and scenic base walks.',
  'Sabah', 'Kundasang', 'Kinabalu Park Headquarters, 89300 Ranau, Sabah', '$$', 'Morning (7:30 AM - 11:30 AM)', 'Walk Silau-Silau nature trail, visit Mountain Botanical Garden, view Mount Kinabalu peaks', NULL,
  6.0042, 116.5441, clock_timestamp() - interval '19 days', clock_timestamp() - interval '18 days',
  clock_timestamp() - interval '19 days', clock_timestamp() - interval '18 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, status = EXCLUDED.status;


INSERT INTO public.spot_revisions (
  id, spot_id, revision_number, author_id, status, name, category, description,
  state, city, address, price_range, best_time, things_to_do, image_path,
  latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0110-0000-0000-000000000016', '00000000-0100-0000-0000-000000000016', 1, NULL, 'approved', 'Sepilok Orangutan Rehabilitation Centre', 'Wildlife', 'World-renowned sanctuary dedicated to rehabilitating orphaned and rescued Bornean orangutans.',
  'Sabah', 'Sandakan', 'W.D.T. 200, 90009 Sandakan, Sabah', '$$', 'Feeding sessions (10:00 AM / 3:00 PM)', 'Watch orangutan feeding sessions from boardwalk, visit outdoor nursery learning center', NULL,
  5.8643, 117.949, clock_timestamp() - interval '18 days', clock_timestamp() - interval '17 days',
  clock_timestamp() - interval '18 days', clock_timestamp() - interval '17 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, status = EXCLUDED.status;


INSERT INTO public.spot_revisions (
  id, spot_id, revision_number, author_id, status, name, category, description,
  state, city, address, price_range, best_time, things_to_do, image_path,
  latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0110-0000-0000-000000000017', '00000000-0100-0000-0000-000000000017', 1, NULL, 'approved', 'Tunku Abdul Rahman Marine Park', 'Marine', 'Cluster of 5 tropical islands off Kota Kinabalu with coral reefs, snorkeling, and sandy beaches.',
  'Sabah', 'Kota Kinabalu', 'Jesselton Point Ferry Terminal, Kota Kinabalu, Sabah', '$$', 'Full day (8:30 AM - 4:00 PM)', 'Island hop between Manukan and Sapi, snorkel crystal clear waters, ride marine zipline', NULL,
  5.9754, 116.0028, clock_timestamp() - interval '17 days', clock_timestamp() - interval '16 days',
  clock_timestamp() - interval '17 days', clock_timestamp() - interval '16 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, status = EXCLUDED.status;


INSERT INTO public.spot_revisions (
  id, spot_id, revision_number, author_id, status, name, category, description,
  state, city, address, price_range, best_time, things_to_do, image_path,
  latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0110-0000-0000-000000000018', '00000000-0100-0000-0000-000000000018', 1, NULL, 'approved', 'Bako National Park', 'Nature', 'Sarawak''s oldest national park featuring coastal sea stacks, jungle trails, and wild proboscis monkeys.',
  'Sarawak', 'Kuching', 'Bako National Park, 93050 Kuching, Sarawak', '$$', 'Early morning boat departure (8:00 AM)', 'Spot proboscis monkeys and bearded pigs, trek Telok Pandan Kecil trail, photograph Sea Stack', NULL,
  1.7167, 110.4667, clock_timestamp() - interval '16 days', clock_timestamp() - interval '15 days',
  clock_timestamp() - interval '16 days', clock_timestamp() - interval '15 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, status = EXCLUDED.status;


INSERT INTO public.spot_revisions (
  id, spot_id, revision_number, author_id, status, name, category, description,
  state, city, address, price_range, best_time, things_to_do, image_path,
  latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0110-0000-0000-000000000019', '00000000-0100-0000-0000-000000000019', 1, NULL, 'approved', 'Sarawak Cultural Village', 'Culture', 'Award-winning living museum showcasing authentic ethnic longhouses, handicrafts, and cultural dances.',
  'Sarawak', 'Santubong', 'Pantai Damai, Santubong, 93752 Kuching, Sarawak', '$$', 'Cultural show times (11:30 AM / 4:00 PM)', 'Explore Iban, Bidayuh, and Orang Ulu longhouses, watch cultural dance performance, try blowpipe', NULL,
  1.7505, 110.3168, clock_timestamp() - interval '15 days', clock_timestamp() - interval '14 days',
  clock_timestamp() - interval '15 days', clock_timestamp() - interval '14 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, status = EXCLUDED.status;


INSERT INTO public.spot_revisions (
  id, spot_id, revision_number, author_id, status, name, category, description,
  state, city, address, price_range, best_time, things_to_do, image_path,
  latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0110-0000-0000-00000000001a', '00000000-0100-0000-0000-00000000001a', 1, NULL, 'approved', 'Kuching Waterfront & Darul Hana Bridge', 'Urban', 'Scenic river esplanade featuring historic colonial landmarks, food kiosks, and the iconic S-shaped bridge.',
  'Sarawak', 'Kuching', 'Jalan Main Bazaar, 93000 Kuching, Sarawak', '$', 'Sunset / Evening (5:30 PM - 9:30 PM)', 'Walk pedestrian Darul Hana Bridge, watch river musical fountain, take traditional tambang boat', NULL,
  1.5594, 110.3444, clock_timestamp() - interval '14 days', clock_timestamp() - interval '13 days',
  clock_timestamp() - interval '14 days', clock_timestamp() - interval '13 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, status = EXCLUDED.status;


INSERT INTO public.spot_revisions (
  id, spot_id, revision_number, author_id, status, name, category, description,
  state, city, address, price_range, best_time, things_to_do, image_path,
  latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0110-0000-0000-00000000001b', '00000000-0100-0000-0000-00000000001b', 1, NULL, 'approved', 'Gunung Mulu National Park', 'Nature', 'UNESCO World Heritage Site famed for colossal limestone caves, karst formations, and bat exodus flights.',
  'Sarawak', 'Miri', 'Gunung Mulu National Park, No 11, Pejabat Pos Mulu, 98070 Mulu, Sarawak', '$$$', 'Morning cave walks & sunset bat exodus (5:00 PM)', 'Tour Deer Cave and Clearwater Cave, watch millions of bats exit at dusk, walk canopy skywalk', NULL,
  4.0489, 114.8118, clock_timestamp() - interval '13 days', clock_timestamp() - interval '12 days',
  clock_timestamp() - interval '13 days', clock_timestamp() - interval '12 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, status = EXCLUDED.status;


INSERT INTO public.spot_revisions (
  id, spot_id, revision_number, author_id, status, name, category, description,
  state, city, address, price_range, best_time, things_to_do, image_path,
  latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0110-0000-0000-00000000001c', '00000000-0100-0000-0000-00000000001c', 1, NULL, 'approved', 'Sultan Salahuddin Abdul Aziz Mosque (Blue Mosque)', 'Architecture', 'Malaysia''s largest mosque with an iconic blue and silver dome, towering minarets, and stained-glass halls.',
  'Selangor', 'Shah Alam', 'Persiaran Masjid, Seksyen 14, 40000 Shah Alam, Selangor', '$', 'Morning or afternoon (guided tour)', 'Join free guided educational tour, admire Islamic decorative arts and calligraphy', NULL,
  3.0784, 101.5208, clock_timestamp() - interval '12 days', clock_timestamp() - interval '11 days',
  clock_timestamp() - interval '12 days', clock_timestamp() - interval '11 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, status = EXCLUDED.status;


INSERT INTO public.spot_revisions (
  id, spot_id, revision_number, author_id, status, name, category, description,
  state, city, address, price_range, best_time, things_to_do, image_path,
  latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0110-0000-0000-00000000001d', '00000000-0100-0000-0000-00000000001d', 1, NULL, 'approved', 'Kuala Selangor Nature Park (Taman Alam)', 'Nature', 'Protected coastal wetland habitat featuring mangrove boardwalks, bird hides, and silvered leaf monkeys.',
  'Selangor', 'Kuala Selangor', 'Jalan Klinik, 45000 Kuala Selangor, Selangor', '$', 'Morning (8:00 AM - 11:00 AM)', 'Walk through mangrove boardwalk, observe migratory birds from watchtowers, see silvered leaf monkeys', NULL,
  3.3396, 101.2464, clock_timestamp() - interval '11 days', clock_timestamp() - interval '10 days',
  clock_timestamp() - interval '11 days', clock_timestamp() - interval '10 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, status = EXCLUDED.status;


INSERT INTO public.spot_revisions (
  id, spot_id, revision_number, author_id, status, name, category, description,
  state, city, address, price_range, best_time, things_to_do, image_path,
  latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0110-0000-0000-00000000001e', '00000000-0100-0000-0000-00000000001e', 1, NULL, 'approved', 'Boh Tea Estate Sungai Palas', 'Agriculture', 'Picturesque tea plantation nestled in the rolling hills with a futuristic tea cafe perched over the valley.',
  'Pahang', 'Cameron Highlands', 'Sungai Palas Garden, 39100 Brinchang, Pahang', '$', 'Morning (8:30 AM - 11:30 AM)', 'Tour tea factory process, taste freshly brewed tea at cantilevered cafe, photograph rolling hills', NULL,
  4.5173, 101.4005, clock_timestamp() - interval '10 days', clock_timestamp() - interval '9 days',
  clock_timestamp() - interval '10 days', clock_timestamp() - interval '9 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, status = EXCLUDED.status;


INSERT INTO public.spot_revisions (
  id, spot_id, revision_number, author_id, status, name, category, description,
  state, city, address, price_range, best_time, things_to_do, image_path,
  latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0110-0000-0000-00000000001f', '00000000-0100-0000-0000-00000000001f', 1, NULL, 'approved', 'Mossy Forest', 'Nature', 'Enchanting high-altitude cloud forest draped in moss, ferns, orchids, and carnivorous pitcher plants.',
  'Pahang', 'Cameron Highlands', 'Gunung Brinchang, 39000 Brinchang, Pahang', '$$', 'Morning (8:00 AM - 11:00 AM)', 'Walk elevated boardwalk through mist-shrouded mossy trees, observe rare montane orchids', NULL,
  4.5238, 101.3824, clock_timestamp() - interval '9 days', clock_timestamp() - interval '8 days',
  clock_timestamp() - interval '9 days', clock_timestamp() - interval '8 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, status = EXCLUDED.status;


INSERT INTO public.spot_revisions (
  id, spot_id, revision_number, author_id, status, name, category, description,
  state, city, address, price_range, best_time, things_to_do, image_path,
  latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0110-0000-0000-000000000020', '00000000-0100-0000-0000-000000000020', 1, NULL, 'approved', 'Langkawi Sky Bridge & SkyCab', 'Engineering', 'Curved pedestrian cable-stayed bridge suspended 660 meters above sea level with sweeping Andaman Sea vistas.',
  'Kedah', 'Langkawi', 'Oriental Village, Burau Bay, 07000 Langkawi, Kedah', '$$$', 'Morning (9:00 AM - 11:30 AM)', 'Ride SkyCab cable car, walk thrilling curved Sky Bridge, admire Andaman island archipelago', NULL,
  6.3712, 99.6617, clock_timestamp() - interval '8 days', clock_timestamp() - interval '7 days',
  clock_timestamp() - interval '8 days', clock_timestamp() - interval '7 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, status = EXCLUDED.status;


INSERT INTO public.spot_revisions (
  id, spot_id, revision_number, author_id, status, name, category, description,
  state, city, address, price_range, best_time, things_to_do, image_path,
  latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0110-0000-0000-000000000021', '00000000-0100-0000-0000-000000000021', 1, NULL, 'approved', 'Islamic Heritage Park (Taman Tamadun Islam)', 'Heritage', 'Riverside monument park featuring intricate replicas of world Islamic landmarks and the Crystal Mosque.',
  'Terengganu', 'Kuala Terengganu', 'Pulau Wan Man, 21000 Kuala Terengganu, Terengganu', '$$', 'Morning or late afternoon', 'Tour world monument replicas via tram, photograph Crystal Mosque by the Terengganu River', NULL,
  5.3015, 103.1189, clock_timestamp() - interval '7 days', clock_timestamp() - interval '6 days',
  clock_timestamp() - interval '7 days', clock_timestamp() - interval '6 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, status = EXCLUDED.status;


INSERT INTO public.spot_revisions (
  id, spot_id, revision_number, author_id, status, name, category, description,
  state, city, address, price_range, best_time, things_to_do, image_path,
  latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0110-0000-0000-000000000022', '00000000-0100-0000-0000-000000000022', 1, NULL, 'approved', 'Tasik Kenyir (Kenyir Lake)', 'Nature', 'Largest man-made lake in Southeast Asia surrounded by tropical rainforest, waterfalls, and herbal islands.',
  'Terengganu', 'Hulu Terengganu', 'Pengkalan Gawi, 21700 Kuala Berang, Terengganu', '$$', 'Full day excursion', 'Cruise lake to Lasir Waterfall, visit Kenyir Elephant Sanctuary, explore herbal garden island', NULL,
  4.9667, 102.8167, clock_timestamp() - interval '6 days', clock_timestamp() - interval '5 days',
  clock_timestamp() - interval '6 days', clock_timestamp() - interval '5 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, status = EXCLUDED.status;


INSERT INTO public.spot_revisions (
  id, spot_id, revision_number, author_id, status, name, category, description,
  state, city, address, price_range, best_time, things_to_do, image_path,
  latitude, longitude, submitted_at, created_at, updated_at
) VALUES (
  '00000000-0110-0000-0000-000000000023', '00000000-0100-0000-0000-000000000023', 1, NULL, 'submitted', 'Penang Botanic Gardens', 'Nature', 'Historic 1884 public botanical gardens known as the Waterfall Gardens, featuring lush flora and macaques.',
  'Pulau Pinang', 'George Town', 'Kompleks Pentadbiran, Bangunan Pavilion, Jalan Kebun Bunga, 10350 George Town, Pulau Pinang', '$', 'Early morning (7:00 AM - 9:30 AM)', 'Walk jogging trails, explore orchid garden, see Cannonball Tree', NULL,
  5.4378, 100.2908, clock_timestamp() - interval '2 days', clock_timestamp() - interval '2 days', clock_timestamp() - interval '2 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, status = EXCLUDED.status;


INSERT INTO public.spot_revisions (
  id, spot_id, revision_number, author_id, status, name, category, description,
  state, city, address, price_range, best_time, things_to_do, image_path,
  latitude, longitude, submitted_at, created_at, updated_at
) VALUES (
  '00000000-0110-0000-0000-000000000024', '00000000-0100-0000-0000-000000000024', 1, NULL, 'submitted', 'Forest Research Institute Malaysia (FRIM)', 'Nature', 'World-renowned tropical forestry research park with arboretums, nature trails, and forest skywalk.',
  'Selangor', 'Kepong', 'Jalan Frim, Kepong, 52109 Kuala Lumpur, Selangor', '$', 'Morning (8:00 AM - 11:00 AM)', 'Walk Forest Skywalk, stroll through botanical arboretums, picnic near Kroh river', NULL,
  3.2361, 101.6347, clock_timestamp() - interval '2 days', clock_timestamp() - interval '2 days', clock_timestamp() - interval '2 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, status = EXCLUDED.status;


INSERT INTO public.spot_revisions (
  id, spot_id, revision_number, author_id, status, name, category, description,
  state, city, address, price_range, best_time, things_to_do, image_path,
  latitude, longitude, submitted_at, created_at, updated_at
) VALUES (
  '00000000-0110-0000-0000-000000000025', '00000000-0100-0000-0000-000000000025', 1, NULL, 'submitted', 'Royal Belum State Park', 'Nature', 'Pristine 130-million-year-old ancient rainforest home to hornbills, Rafflesia flowers, and indigenous Orang Asli.',
  'Perak', 'Gerik', 'Pulau Banding, 33200 Gerik, Perak', '$$$', 'Multi-day expedition', 'Search for Rafflesia blooms, cruise Temenggor Lake, trek to waterfall salt licks', NULL,
  5.6167, 101.3667, clock_timestamp() - interval '2 days', clock_timestamp() - interval '2 days', clock_timestamp() - interval '2 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, status = EXCLUDED.status;


-- 1.3 PUBLISHED SPOTS & SPOTS POINTER UPDATES

UPDATE public.spots SET current_revision_id = '00000000-0110-0000-0000-000000000001', approved_revision_id = '00000000-0110-0000-0000-000000000001' WHERE id = '00000000-0100-0000-0000-000000000001';

INSERT INTO public.published_spots (
  id, revision_id, name, category, description, state, city, address,
  price_range, best_time, things_to_do, image_path, latitude, longitude,
  rating_average, review_count, published_at, updated_at, upvote_count
) VALUES (
  '00000000-0100-0000-0000-000000000001', '00000000-0110-0000-0000-000000000001', 'Batu Caves', 'Culture', 'Iconic limestone caves and Hindu shrine with 272 colorful steps and towering Lord Murugan statue.', 'Selangor', 'Gombak', 'Gombak, 68100 Batu Caves, Selangor',
  '$', 'Early morning (7:00 AM - 9:00 AM)', 'Climb the 272 steps, visit Temple Cave, explore Dark Cave conservation tour', NULL, 3.2379, 101.684,
  4.7, 18, clock_timestamp() - interval '38 days', clock_timestamp() - interval '38 days', 25
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, category = EXCLUDED.category,
  description = EXCLUDED.description, state = EXCLUDED.state, city = EXCLUDED.city,
  address = EXCLUDED.address, price_range = EXCLUDED.price_range, best_time = EXCLUDED.best_time,
  things_to_do = EXCLUDED.things_to_do, latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count, upvote_count = EXCLUDED.upvote_count;


UPDATE public.spots SET current_revision_id = '00000000-0110-0000-0000-000000000002', approved_revision_id = '00000000-0110-0000-0000-000000000002' WHERE id = '00000000-0100-0000-0000-000000000002';

INSERT INTO public.published_spots (
  id, revision_id, name, category, description, state, city, address,
  price_range, best_time, things_to_do, image_path, latitude, longitude,
  rating_average, review_count, published_at, updated_at, upvote_count
) VALUES (
  '00000000-0100-0000-0000-000000000002', '00000000-0110-0000-0000-000000000002', 'Petronas Twin Towers & KLCC Park', 'Landmark', 'World''s tallest twin structures offering city views and a landscaped 50-acre tropical park.', 'Kuala Lumpur', 'Kuala Lumpur', 'Concourse Level, Petronas Twin Tower, Lower Ground, KLCC, 50088 Kuala Lumpur',
  '$$', 'Evening / Sunset (5:30 PM - 8:00 PM)', 'Walk the Skybridge, photograph the Lake Symphony water fountain show, jog in KLCC Park', NULL, 3.1579, 101.7116,
  4.8, 24, clock_timestamp() - interval '37 days', clock_timestamp() - interval '37 days', 40
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, category = EXCLUDED.category,
  description = EXCLUDED.description, state = EXCLUDED.state, city = EXCLUDED.city,
  address = EXCLUDED.address, price_range = EXCLUDED.price_range, best_time = EXCLUDED.best_time,
  things_to_do = EXCLUDED.things_to_do, latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count, upvote_count = EXCLUDED.upvote_count;


UPDATE public.spots SET current_revision_id = '00000000-0110-0000-0000-000000000003', approved_revision_id = '00000000-0110-0000-0000-000000000003' WHERE id = '00000000-0100-0000-0000-000000000003';

INSERT INTO public.published_spots (
  id, revision_id, name, category, description, state, city, address,
  price_range, best_time, things_to_do, image_path, latitude, longitude,
  rating_average, review_count, published_at, updated_at, upvote_count
) VALUES (
  '00000000-0100-0000-0000-000000000003', '00000000-0110-0000-0000-000000000003', 'Thean Hou Temple', 'Culture', 'Six-tiered Chinese temple combining Buddhism, Taoism, and Confucianism with panoramic KL skyline views.', 'Kuala Lumpur', 'Kuala Lumpur', '65, Persiaran Endah, Taman Persiaran Desa, 50460 Kuala Lumpur',
  '$', 'Morning or late afternoon', 'Admire traditional architecture, view lanterns, enjoy city panoramas from top tier', NULL, 3.1219, 101.6869,
  4.6, 15, clock_timestamp() - interval '36 days', clock_timestamp() - interval '36 days', 18
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, category = EXCLUDED.category,
  description = EXCLUDED.description, state = EXCLUDED.state, city = EXCLUDED.city,
  address = EXCLUDED.address, price_range = EXCLUDED.price_range, best_time = EXCLUDED.best_time,
  things_to_do = EXCLUDED.things_to_do, latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count, upvote_count = EXCLUDED.upvote_count;


UPDATE public.spots SET current_revision_id = '00000000-0110-0000-0000-000000000004', approved_revision_id = '00000000-0110-0000-0000-000000000004' WHERE id = '00000000-0100-0000-0000-000000000004';

INSERT INTO public.published_spots (
  id, revision_id, name, category, description, state, city, address,
  price_range, best_time, things_to_do, image_path, latitude, longitude,
  rating_average, review_count, published_at, updated_at, upvote_count
) VALUES (
  '00000000-0100-0000-0000-000000000004', '00000000-0110-0000-0000-000000000004', 'KL Forest Eco Park', 'Nature', 'One of the oldest permanent forest reserves in Malaysia with a lush canopy walk in the city center.', 'Kuala Lumpur', 'Kuala Lumpur', 'Lot 240, Jalan Raja Chulan, Bukit Kewangan, 50250 Kuala Lumpur',
  '$', 'Morning (8:00 AM - 10:30 AM)', 'Trek canopy walk bridges, discover tropical rainforest flora and fauna', NULL, 3.1504, 101.7018,
  4.4, 12, clock_timestamp() - interval '35 days', clock_timestamp() - interval '35 days', 14
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, category = EXCLUDED.category,
  description = EXCLUDED.description, state = EXCLUDED.state, city = EXCLUDED.city,
  address = EXCLUDED.address, price_range = EXCLUDED.price_range, best_time = EXCLUDED.best_time,
  things_to_do = EXCLUDED.things_to_do, latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count, upvote_count = EXCLUDED.upvote_count;


UPDATE public.spots SET current_revision_id = '00000000-0110-0000-0000-000000000005', approved_revision_id = '00000000-0110-0000-0000-000000000005' WHERE id = '00000000-0100-0000-0000-000000000005';

INSERT INTO public.published_spots (
  id, revision_id, name, category, description, state, city, address,
  price_range, best_time, things_to_do, image_path, latitude, longitude,
  rating_average, review_count, published_at, updated_at, upvote_count
) VALUES (
  '00000000-0100-0000-0000-000000000005', '00000000-0110-0000-0000-000000000005', 'Kek Lok Si Temple', 'Culture', 'Sprawling Buddhist temple complex featuring the 7-tier Pagoda of Rama VI and bronze Guanyin statue.', 'Pulau Pinang', 'Air Itam', '1000-L, Tingkat Lembah Ria 1, 11500 Ayer Itam, Pulau Pinang',
  '$', 'Morning (8:30 AM - 11:00 AM)', 'Climb the Pagoda of 10,000 Buddhas, ride the inclined lift to Guanyin Pavilion, buy prayer ribbons', NULL, 5.3995, 100.2736,
  4.8, 22, clock_timestamp() - interval '34 days', clock_timestamp() - interval '34 days', 35
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, category = EXCLUDED.category,
  description = EXCLUDED.description, state = EXCLUDED.state, city = EXCLUDED.city,
  address = EXCLUDED.address, price_range = EXCLUDED.price_range, best_time = EXCLUDED.best_time,
  things_to_do = EXCLUDED.things_to_do, latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count, upvote_count = EXCLUDED.upvote_count;


UPDATE public.spots SET current_revision_id = '00000000-0110-0000-0000-000000000006', approved_revision_id = '00000000-0110-0000-0000-000000000006' WHERE id = '00000000-0100-0000-0000-000000000006';

INSERT INTO public.published_spots (
  id, revision_id, name, category, description, state, city, address,
  price_range, best_time, things_to_do, image_path, latitude, longitude,
  rating_average, review_count, published_at, updated_at, upvote_count
) VALUES (
  '00000000-0100-0000-0000-000000000006', '00000000-0110-0000-0000-000000000006', 'Penang Hill (Bukit Bendera)', 'Nature', 'Cool hill resort accessible via historic funicular railway with rainforest walks and heritage bungalows.', 'Pulau Pinang', 'Air Itam', 'Jalan Stesen Bukit Bendera, 11500 Air Itam, Penang',
  '$$', 'Early morning or late afternoon', 'Ride funicular railway, walk The Habitat Curtis Crest treetop walk, visit heritage post office', NULL, 5.4242, 100.269,
  4.7, 19, clock_timestamp() - interval '33 days', clock_timestamp() - interval '33 days', 30
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, category = EXCLUDED.category,
  description = EXCLUDED.description, state = EXCLUDED.state, city = EXCLUDED.city,
  address = EXCLUDED.address, price_range = EXCLUDED.price_range, best_time = EXCLUDED.best_time,
  things_to_do = EXCLUDED.things_to_do, latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count, upvote_count = EXCLUDED.upvote_count;


UPDATE public.spots SET current_revision_id = '00000000-0110-0000-0000-000000000007', approved_revision_id = '00000000-0110-0000-0000-000000000007' WHERE id = '00000000-0100-0000-0000-000000000007';

INSERT INTO public.published_spots (
  id, revision_id, name, category, description, state, city, address,
  price_range, best_time, things_to_do, image_path, latitude, longitude,
  rating_average, review_count, published_at, updated_at, upvote_count
) VALUES (
  '00000000-0100-0000-0000-000000000007', '00000000-0110-0000-0000-000000000007', 'Cheong Fatt Tze - The Blue Mansion', 'Heritage', 'Restored 19th-century courtyard mansion famous for its indigo-blue exterior and Feng Shui architecture.', 'Pulau Pinang', 'George Town', '14, Leith St, George Town, 10200 George Town, Pulau Pinang',
  '$$', 'Guided tour slots (11:00 AM / 2:00 PM)', 'Join guided architectural heritage tour, enjoy courtyard refreshments', NULL, 5.4206, 100.3344,
  4.6, 14, clock_timestamp() - interval '32 days', clock_timestamp() - interval '32 days', 22
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, category = EXCLUDED.category,
  description = EXCLUDED.description, state = EXCLUDED.state, city = EXCLUDED.city,
  address = EXCLUDED.address, price_range = EXCLUDED.price_range, best_time = EXCLUDED.best_time,
  things_to_do = EXCLUDED.things_to_do, latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count, upvote_count = EXCLUDED.upvote_count;


UPDATE public.spots SET current_revision_id = '00000000-0110-0000-0000-000000000008', approved_revision_id = '00000000-0110-0000-0000-000000000008' WHERE id = '00000000-0100-0000-0000-000000000008';

INSERT INTO public.published_spots (
  id, revision_id, name, category, description, state, city, address,
  price_range, best_time, things_to_do, image_path, latitude, longitude,
  rating_average, review_count, published_at, updated_at, upvote_count
) VALUES (
  '00000000-0100-0000-0000-000000000008', '00000000-0110-0000-0000-000000000008', 'Pinang Peranakan Mansion', 'Heritage', 'Opulent museum displaying Straits Chinese Peranakan antiques, gold jewelry, and Baba-Nyonya lifestyle.', 'Pulau Pinang', 'George Town', '29, Church St, George Town, 10200 George Town, Pulau Pinang',
  '$$', 'Morning to afternoon (9:30 AM - 4:00 PM)', 'Explore restored Peranakan rooms, view vintage jewellery and antique ceramics', NULL, 5.4182, 100.3409,
  4.7, 16, clock_timestamp() - interval '31 days', clock_timestamp() - interval '31 days', 26
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, category = EXCLUDED.category,
  description = EXCLUDED.description, state = EXCLUDED.state, city = EXCLUDED.city,
  address = EXCLUDED.address, price_range = EXCLUDED.price_range, best_time = EXCLUDED.best_time,
  things_to_do = EXCLUDED.things_to_do, latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count, upvote_count = EXCLUDED.upvote_count;


UPDATE public.spots SET current_revision_id = '00000000-0110-0000-0000-000000000009', approved_revision_id = '00000000-0110-0000-0000-000000000009' WHERE id = '00000000-0100-0000-0000-000000000009';

INSERT INTO public.published_spots (
  id, revision_id, name, category, description, state, city, address,
  price_range, best_time, things_to_do, image_path, latitude, longitude,
  rating_average, review_count, published_at, updated_at, upvote_count
) VALUES (
  '00000000-0100-0000-0000-000000000009', '00000000-0110-0000-0000-000000000009', 'A Famosa (Porta de Santiago)', 'Historical', 'Historic 16th-century Portuguese fortress gate standing as one of Southeast Asia''s oldest European architectural remains.', 'Melaka', 'Melaka', 'Jalan Kota, Bandar Hilir, 75000 Melaka',
  '$', 'Morning or sunset', 'Photograph historic stone gate, read historical markers, walk up to St. Paul''s Hill', NULL, 2.192, 102.2494,
  4.5, 20, clock_timestamp() - interval '30 days', clock_timestamp() - interval '30 days', 28
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, category = EXCLUDED.category,
  description = EXCLUDED.description, state = EXCLUDED.state, city = EXCLUDED.city,
  address = EXCLUDED.address, price_range = EXCLUDED.price_range, best_time = EXCLUDED.best_time,
  things_to_do = EXCLUDED.things_to_do, latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count, upvote_count = EXCLUDED.upvote_count;


UPDATE public.spots SET current_revision_id = '00000000-0110-0000-0000-00000000000a', approved_revision_id = '00000000-0110-0000-0000-00000000000a' WHERE id = '00000000-0100-0000-0000-00000000000a';

INSERT INTO public.published_spots (
  id, revision_id, name, category, description, state, city, address,
  price_range, best_time, things_to_do, image_path, latitude, longitude,
  rating_average, review_count, published_at, updated_at, upvote_count
) VALUES (
  '00000000-0100-0000-0000-00000000000a', '00000000-0110-0000-0000-00000000000a', 'St. Paul''s Hill & Church', 'Historical', 'Ruined 1521 Portuguese church with historic Dutch tombstones and scenic vistas of Melaka Straits.', 'Melaka', 'Melaka', 'Jalan Kota, Bandar Hilir, 75000 Melaka',
  '$', 'Late afternoon / Sunset', 'View historic tombstones, statue of St. Francis Xavier, watch sunset over the Straits', NULL, 2.1928, 102.2492,
  4.5, 14, clock_timestamp() - interval '29 days', clock_timestamp() - interval '29 days', 19
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, category = EXCLUDED.category,
  description = EXCLUDED.description, state = EXCLUDED.state, city = EXCLUDED.city,
  address = EXCLUDED.address, price_range = EXCLUDED.price_range, best_time = EXCLUDED.best_time,
  things_to_do = EXCLUDED.things_to_do, latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count, upvote_count = EXCLUDED.upvote_count;


UPDATE public.spots SET current_revision_id = '00000000-0110-0000-0000-00000000000b', approved_revision_id = '00000000-0110-0000-0000-00000000000b' WHERE id = '00000000-0100-0000-0000-00000000000b';

INSERT INTO public.published_spots (
  id, revision_id, name, category, description, state, city, address,
  price_range, best_time, things_to_do, image_path, latitude, longitude,
  rating_average, review_count, published_at, updated_at, upvote_count
) VALUES (
  '00000000-0100-0000-0000-00000000000b', '00000000-0110-0000-0000-00000000000b', 'Jonker Street Night Market', 'Culture', 'Bustling weekend street market filled with local street food, antique crafts, and cultural performances.', 'Melaka', 'Melaka', 'Jalan Hang Jebat, 75200 Melaka',
  '$', 'Friday - Sunday evenings (6:00 PM - 11:00 PM)', 'Sample local snacks, browse craft stalls, watch stage performances at Jonker Walk stage', NULL, 2.1956, 102.2476,
  4.6, 28, clock_timestamp() - interval '28 days', clock_timestamp() - interval '28 days', 45
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, category = EXCLUDED.category,
  description = EXCLUDED.description, state = EXCLUDED.state, city = EXCLUDED.city,
  address = EXCLUDED.address, price_range = EXCLUDED.price_range, best_time = EXCLUDED.best_time,
  things_to_do = EXCLUDED.things_to_do, latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count, upvote_count = EXCLUDED.upvote_count;


UPDATE public.spots SET current_revision_id = '00000000-0110-0000-0000-00000000000c', approved_revision_id = '00000000-0110-0000-0000-00000000000c' WHERE id = '00000000-0100-0000-0000-00000000000c';

INSERT INTO public.published_spots (
  id, revision_id, name, category, description, state, city, address,
  price_range, best_time, things_to_do, image_path, latitude, longitude,
  rating_average, review_count, published_at, updated_at, upvote_count
) VALUES (
  '00000000-0100-0000-0000-00000000000c', '00000000-0110-0000-0000-00000000000c', 'Baba & Nyonya Heritage Museum', 'Heritage', 'Preserved ancestral townhouse offering guided insights into rich Peranakan culture and traditions.', 'Melaka', 'Melaka', '48-50, Jalan Tun Tan Cheng Lock, 75200 Melaka',
  '$$', 'Morning (10:00 AM - 1:00 PM)', 'Take guided museum tour, learn about Peranakan customs, observe historic courtyard architecture', NULL, 2.1952, 102.2464,
  4.7, 11, clock_timestamp() - interval '27 days', clock_timestamp() - interval '27 days', 15
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, category = EXCLUDED.category,
  description = EXCLUDED.description, state = EXCLUDED.state, city = EXCLUDED.city,
  address = EXCLUDED.address, price_range = EXCLUDED.price_range, best_time = EXCLUDED.best_time,
  things_to_do = EXCLUDED.things_to_do, latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count, upvote_count = EXCLUDED.upvote_count;


UPDATE public.spots SET current_revision_id = '00000000-0110-0000-0000-00000000000d', approved_revision_id = '00000000-0110-0000-0000-00000000000d' WHERE id = '00000000-0100-0000-0000-00000000000d';

INSERT INTO public.published_spots (
  id, revision_id, name, category, description, state, city, address,
  price_range, best_time, things_to_do, image_path, latitude, longitude,
  rating_average, review_count, published_at, updated_at, upvote_count
) VALUES (
  '00000000-0100-0000-0000-00000000000d', '00000000-0110-0000-0000-00000000000d', 'Kellie''s Castle', 'Historical', 'Unfinished Scottish mansion built in 1915 with hidden rooms, secret underground tunnels, and rooftop views.', 'Perak', 'Batu Gajah', 'Lot 48436, Kompleks Pelancongan Kellie''s Castle, KM 5.5, Jalan Gopeng, 31000 Batu Gajah, Perak',
  '$', 'Morning or late afternoon', 'Explore hidden wine cellar and elevator shaft, photograph Gothic-Greco-Roman architecture', NULL, 4.4754, 101.0877,
  4.4, 13, clock_timestamp() - interval '26 days', clock_timestamp() - interval '26 days', 17
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, category = EXCLUDED.category,
  description = EXCLUDED.description, state = EXCLUDED.state, city = EXCLUDED.city,
  address = EXCLUDED.address, price_range = EXCLUDED.price_range, best_time = EXCLUDED.best_time,
  things_to_do = EXCLUDED.things_to_do, latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count, upvote_count = EXCLUDED.upvote_count;


UPDATE public.spots SET current_revision_id = '00000000-0110-0000-0000-00000000000e', approved_revision_id = '00000000-0110-0000-0000-00000000000e' WHERE id = '00000000-0100-0000-0000-00000000000e';

INSERT INTO public.published_spots (
  id, revision_id, name, category, description, state, city, address,
  price_range, best_time, things_to_do, image_path, latitude, longitude,
  rating_average, review_count, published_at, updated_at, upvote_count
) VALUES (
  '00000000-0100-0000-0000-00000000000e', '00000000-0110-0000-0000-00000000000e', 'Perak Cave Temple (Perak Tong)', 'Culture', 'Limestone cave temple housing a 40-foot sitting Buddha and vibrant traditional murals with a panoramic summit climb.', 'Perak', 'Ipoh', 'Jalan Kuala Kangsar, Kawasan Perindustrian Tasek, 31400 Ipoh, Perak',
  '$', 'Morning (9:00 AM - 12:00 PM)', 'Admire cave murals and giant Buddha, climb stairs to panoramic summit lookout', NULL, 4.6469, 101.0991,
  4.6, 16, clock_timestamp() - interval '25 days', clock_timestamp() - interval '25 days', 21
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, category = EXCLUDED.category,
  description = EXCLUDED.description, state = EXCLUDED.state, city = EXCLUDED.city,
  address = EXCLUDED.address, price_range = EXCLUDED.price_range, best_time = EXCLUDED.best_time,
  things_to_do = EXCLUDED.things_to_do, latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count, upvote_count = EXCLUDED.upvote_count;


UPDATE public.spots SET current_revision_id = '00000000-0110-0000-0000-00000000000f', approved_revision_id = '00000000-0110-0000-0000-00000000000f' WHERE id = '00000000-0100-0000-0000-00000000000f';

INSERT INTO public.published_spots (
  id, revision_id, name, category, description, state, city, address,
  price_range, best_time, things_to_do, image_path, latitude, longitude,
  rating_average, review_count, published_at, updated_at, upvote_count
) VALUES (
  '00000000-0100-0000-0000-00000000000f', '00000000-0110-0000-0000-00000000000f', 'Concubine Lane (Panglima Lane)', 'Heritage', 'Heritage alley in Ipoh Old Town bustling with artisanal cafes, souvenir stalls, and colonial shophouses.', 'Perak', 'Ipoh', 'Panglima Ln, 30000 Ipoh, Perak',
  '$', 'Morning to late afternoon (10:00 AM - 4:00 PM)', 'Stroll historical lane, sample rain-drop cake and tofu pudding, take street art photos', NULL, 4.5969, 101.0783,
  4.5, 25, clock_timestamp() - interval '24 days', clock_timestamp() - interval '24 days', 38
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, category = EXCLUDED.category,
  description = EXCLUDED.description, state = EXCLUDED.state, city = EXCLUDED.city,
  address = EXCLUDED.address, price_range = EXCLUDED.price_range, best_time = EXCLUDED.best_time,
  things_to_do = EXCLUDED.things_to_do, latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count, upvote_count = EXCLUDED.upvote_count;


UPDATE public.spots SET current_revision_id = '00000000-0110-0000-0000-000000000010', approved_revision_id = '00000000-0110-0000-0000-000000000010' WHERE id = '00000000-0100-0000-0000-000000000010';

INSERT INTO public.published_spots (
  id, revision_id, name, category, description, state, city, address,
  price_range, best_time, things_to_do, image_path, latitude, longitude,
  rating_average, review_count, published_at, updated_at, upvote_count
) VALUES (
  '00000000-0100-0000-0000-000000000010', '00000000-0110-0000-0000-000000000010', 'Tempurung Cave (Gua Tempurung)', 'Nature', 'Massive show cave system stretching over 3 km with impressive stalactites, stalagmites, and subterranean stream walks.', 'Perak', 'Gopeng', 'Pusat Pelancongan Gua Tempurung, 31600 Gopeng, Perak',
  '$$', 'Morning (9:00 AM - 1:00 PM)', 'Choose guided dry or wet caving adventure, view Golden Flowstone chamber', NULL, 4.4172, 101.1878,
  4.7, 17, clock_timestamp() - interval '23 days', clock_timestamp() - interval '23 days', 29
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, category = EXCLUDED.category,
  description = EXCLUDED.description, state = EXCLUDED.state, city = EXCLUDED.city,
  address = EXCLUDED.address, price_range = EXCLUDED.price_range, best_time = EXCLUDED.best_time,
  things_to_do = EXCLUDED.things_to_do, latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count, upvote_count = EXCLUDED.upvote_count;


UPDATE public.spots SET current_revision_id = '00000000-0110-0000-0000-000000000011', approved_revision_id = '00000000-0110-0000-0000-000000000011' WHERE id = '00000000-0100-0000-0000-000000000011';

INSERT INTO public.published_spots (
  id, revision_id, name, category, description, state, city, address,
  price_range, best_time, things_to_do, image_path, latitude, longitude,
  rating_average, review_count, published_at, updated_at, upvote_count
) VALUES (
  '00000000-0100-0000-0000-000000000011', '00000000-0110-0000-0000-000000000011', 'Sultan Abu Bakar State Mosque', 'Architecture', '19th-century Victorian and Moorish-inspired royal mosque overlooking the Straits of Johor.', 'Johor', 'Johor Bahru', 'Jalan Skudai, Bandar Johor Bahru, 80000 Johor Bahru, Johor',
  '$', 'Morning (outside prayer times)', 'Appreciate Victorian-Moorish architectural details, enjoy scenic views of the straits', NULL, 1.458, 103.7554,
  4.6, 12, clock_timestamp() - interval '22 days', clock_timestamp() - interval '22 days', 16
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, category = EXCLUDED.category,
  description = EXCLUDED.description, state = EXCLUDED.state, city = EXCLUDED.city,
  address = EXCLUDED.address, price_range = EXCLUDED.price_range, best_time = EXCLUDED.best_time,
  things_to_do = EXCLUDED.things_to_do, latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count, upvote_count = EXCLUDED.upvote_count;


UPDATE public.spots SET current_revision_id = '00000000-0110-0000-0000-000000000012', approved_revision_id = '00000000-0110-0000-0000-000000000012' WHERE id = '00000000-0100-0000-0000-000000000012';

INSERT INTO public.published_spots (
  id, revision_id, name, category, description, state, city, address,
  price_range, best_time, things_to_do, image_path, latitude, longitude,
  rating_average, review_count, published_at, updated_at, upvote_count
) VALUES (
  '00000000-0100-0000-0000-000000000012', '00000000-0110-0000-0000-000000000012', 'Tan Hiok Nee Heritage Walk', 'Heritage', 'Historic cultural street in Johor Bahru honoring early Chinese pioneer heritage, with bakeries and cafes.', 'Johor', 'Johor Bahru', 'Jalan Tan Hiok Nee, Bandar Johor Bahru, 80000 Johor Bahru, Johor',
  '$', 'Morning to afternoon', 'Taste wood-fired banana cakes, visit heritage kopitiams, admire street murals', NULL, 1.4568, 103.7645,
  4.5, 21, clock_timestamp() - interval '21 days', clock_timestamp() - interval '21 days', 33
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, category = EXCLUDED.category,
  description = EXCLUDED.description, state = EXCLUDED.state, city = EXCLUDED.city,
  address = EXCLUDED.address, price_range = EXCLUDED.price_range, best_time = EXCLUDED.best_time,
  things_to_do = EXCLUDED.things_to_do, latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count, upvote_count = EXCLUDED.upvote_count;


UPDATE public.spots SET current_revision_id = '00000000-0110-0000-0000-000000000013', approved_revision_id = '00000000-0110-0000-0000-000000000013' WHERE id = '00000000-0100-0000-0000-000000000013';

INSERT INTO public.published_spots (
  id, revision_id, name, category, description, state, city, address,
  price_range, best_time, things_to_do, image_path, latitude, longitude,
  rating_average, review_count, published_at, updated_at, upvote_count
) VALUES (
  '00000000-0100-0000-0000-000000000013', '00000000-0110-0000-0000-000000000013', 'Desaru Coast & Beach', 'Nature', 'Pristine 17 km coastline offering golden sand beaches, coastal water sports, and relaxed family recreation.', 'Johor', 'Bandar Penawar', 'Bandar Penawar, 81930 Kota Tinggi, Johor',
  '$', 'Sunrise or late afternoon', 'Relax on public beach, participate in water sports, explore coastal walking trails', NULL, 1.5544, 104.2582,
  4.6, 18, clock_timestamp() - interval '20 days', clock_timestamp() - interval '20 days', 27
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, category = EXCLUDED.category,
  description = EXCLUDED.description, state = EXCLUDED.state, city = EXCLUDED.city,
  address = EXCLUDED.address, price_range = EXCLUDED.price_range, best_time = EXCLUDED.best_time,
  things_to_do = EXCLUDED.things_to_do, latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count, upvote_count = EXCLUDED.upvote_count;


UPDATE public.spots SET current_revision_id = '00000000-0110-0000-0000-000000000014', approved_revision_id = '00000000-0110-0000-0000-000000000014' WHERE id = '00000000-0100-0000-0000-000000000014';

INSERT INTO public.published_spots (
  id, revision_id, name, category, description, state, city, address,
  price_range, best_time, things_to_do, image_path, latitude, longitude,
  rating_average, review_count, published_at, updated_at, upvote_count
) VALUES (
  '00000000-0100-0000-0000-000000000014', '00000000-0110-0000-0000-000000000014', 'Tanjung Piai National Park', 'Nature', 'Southernmost tip of mainland Asia with mangrove boardwalks, mudskippers, and international shipping lane views.', 'Johor', 'Pontian', 'Mukim Serkat, 82030 Pontian, Johor',
  '$', 'Morning or late afternoon', 'Stand at the Southernmost Tip globe monument, walk mangrove boardwalks, spot migratory birds', NULL, 1.2662, 103.51,
  4.5, 14, clock_timestamp() - interval '19 days', clock_timestamp() - interval '19 days', 18
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, category = EXCLUDED.category,
  description = EXCLUDED.description, state = EXCLUDED.state, city = EXCLUDED.city,
  address = EXCLUDED.address, price_range = EXCLUDED.price_range, best_time = EXCLUDED.best_time,
  things_to_do = EXCLUDED.things_to_do, latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count, upvote_count = EXCLUDED.upvote_count;


UPDATE public.spots SET current_revision_id = '00000000-0110-0000-0000-000000000015', approved_revision_id = '00000000-0110-0000-0000-000000000015' WHERE id = '00000000-0100-0000-0000-000000000015';

INSERT INTO public.published_spots (
  id, revision_id, name, category, description, state, city, address,
  price_range, best_time, things_to_do, image_path, latitude, longitude,
  rating_average, review_count, published_at, updated_at, upvote_count
) VALUES (
  '00000000-0100-0000-0000-000000000015', '00000000-0110-0000-0000-000000000015', 'Kinabalu Park & Mount Kinabalu', 'Nature', 'UNESCO World Heritage Site with hyper-diverse mountain flora, botanical gardens, and scenic base walks.', 'Sabah', 'Kundasang', 'Kinabalu Park Headquarters, 89300 Ranau, Sabah',
  '$$', 'Morning (7:30 AM - 11:30 AM)', 'Walk Silau-Silau nature trail, visit Mountain Botanical Garden, view Mount Kinabalu peaks', NULL, 6.0042, 116.5441,
  4.9, 29, clock_timestamp() - interval '18 days', clock_timestamp() - interval '18 days', 52
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, category = EXCLUDED.category,
  description = EXCLUDED.description, state = EXCLUDED.state, city = EXCLUDED.city,
  address = EXCLUDED.address, price_range = EXCLUDED.price_range, best_time = EXCLUDED.best_time,
  things_to_do = EXCLUDED.things_to_do, latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count, upvote_count = EXCLUDED.upvote_count;


UPDATE public.spots SET current_revision_id = '00000000-0110-0000-0000-000000000016', approved_revision_id = '00000000-0110-0000-0000-000000000016' WHERE id = '00000000-0100-0000-0000-000000000016';

INSERT INTO public.published_spots (
  id, revision_id, name, category, description, state, city, address,
  price_range, best_time, things_to_do, image_path, latitude, longitude,
  rating_average, review_count, published_at, updated_at, upvote_count
) VALUES (
  '00000000-0100-0000-0000-000000000016', '00000000-0110-0000-0000-000000000016', 'Sepilok Orangutan Rehabilitation Centre', 'Wildlife', 'World-renowned sanctuary dedicated to rehabilitating orphaned and rescued Bornean orangutans.', 'Sabah', 'Sandakan', 'W.D.T. 200, 90009 Sandakan, Sabah',
  '$$', 'Feeding sessions (10:00 AM / 3:00 PM)', 'Watch orangutan feeding sessions from boardwalk, visit outdoor nursery learning center', NULL, 5.8643, 117.949,
  4.8, 26, clock_timestamp() - interval '17 days', clock_timestamp() - interval '17 days', 44
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, category = EXCLUDED.category,
  description = EXCLUDED.description, state = EXCLUDED.state, city = EXCLUDED.city,
  address = EXCLUDED.address, price_range = EXCLUDED.price_range, best_time = EXCLUDED.best_time,
  things_to_do = EXCLUDED.things_to_do, latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count, upvote_count = EXCLUDED.upvote_count;


UPDATE public.spots SET current_revision_id = '00000000-0110-0000-0000-000000000017', approved_revision_id = '00000000-0110-0000-0000-000000000017' WHERE id = '00000000-0100-0000-0000-000000000017';

INSERT INTO public.published_spots (
  id, revision_id, name, category, description, state, city, address,
  price_range, best_time, things_to_do, image_path, latitude, longitude,
  rating_average, review_count, published_at, updated_at, upvote_count
) VALUES (
  '00000000-0100-0000-0000-000000000017', '00000000-0110-0000-0000-000000000017', 'Tunku Abdul Rahman Marine Park', 'Marine', 'Cluster of 5 tropical islands off Kota Kinabalu with coral reefs, snorkeling, and sandy beaches.', 'Sabah', 'Kota Kinabalu', 'Jesselton Point Ferry Terminal, Kota Kinabalu, Sabah',
  '$$', 'Full day (8:30 AM - 4:00 PM)', 'Island hop between Manukan and Sapi, snorkel crystal clear waters, ride marine zipline', NULL, 5.9754, 116.0028,
  4.7, 24, clock_timestamp() - interval '16 days', clock_timestamp() - interval '16 days', 39
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, category = EXCLUDED.category,
  description = EXCLUDED.description, state = EXCLUDED.state, city = EXCLUDED.city,
  address = EXCLUDED.address, price_range = EXCLUDED.price_range, best_time = EXCLUDED.best_time,
  things_to_do = EXCLUDED.things_to_do, latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count, upvote_count = EXCLUDED.upvote_count;


UPDATE public.spots SET current_revision_id = '00000000-0110-0000-0000-000000000018', approved_revision_id = '00000000-0110-0000-0000-000000000018' WHERE id = '00000000-0100-0000-0000-000000000018';

INSERT INTO public.published_spots (
  id, revision_id, name, category, description, state, city, address,
  price_range, best_time, things_to_do, image_path, latitude, longitude,
  rating_average, review_count, published_at, updated_at, upvote_count
) VALUES (
  '00000000-0100-0000-0000-000000000018', '00000000-0110-0000-0000-000000000018', 'Bako National Park', 'Nature', 'Sarawak''s oldest national park featuring coastal sea stacks, jungle trails, and wild proboscis monkeys.', 'Sarawak', 'Kuching', 'Bako National Park, 93050 Kuching, Sarawak',
  '$$', 'Early morning boat departure (8:00 AM)', 'Spot proboscis monkeys and bearded pigs, trek Telok Pandan Kecil trail, photograph Sea Stack', NULL, 1.7167, 110.4667,
  4.8, 23, clock_timestamp() - interval '15 days', clock_timestamp() - interval '15 days', 41
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, category = EXCLUDED.category,
  description = EXCLUDED.description, state = EXCLUDED.state, city = EXCLUDED.city,
  address = EXCLUDED.address, price_range = EXCLUDED.price_range, best_time = EXCLUDED.best_time,
  things_to_do = EXCLUDED.things_to_do, latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count, upvote_count = EXCLUDED.upvote_count;


UPDATE public.spots SET current_revision_id = '00000000-0110-0000-0000-000000000019', approved_revision_id = '00000000-0110-0000-0000-000000000019' WHERE id = '00000000-0100-0000-0000-000000000019';

INSERT INTO public.published_spots (
  id, revision_id, name, category, description, state, city, address,
  price_range, best_time, things_to_do, image_path, latitude, longitude,
  rating_average, review_count, published_at, updated_at, upvote_count
) VALUES (
  '00000000-0100-0000-0000-000000000019', '00000000-0110-0000-0000-000000000019', 'Sarawak Cultural Village', 'Culture', 'Award-winning living museum showcasing authentic ethnic longhouses, handicrafts, and cultural dances.', 'Sarawak', 'Santubong', 'Pantai Damai, Santubong, 93752 Kuching, Sarawak',
  '$$', 'Cultural show times (11:30 AM / 4:00 PM)', 'Explore Iban, Bidayuh, and Orang Ulu longhouses, watch cultural dance performance, try blowpipe', NULL, 1.7505, 110.3168,
  4.7, 20, clock_timestamp() - interval '14 days', clock_timestamp() - interval '14 days', 31
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, category = EXCLUDED.category,
  description = EXCLUDED.description, state = EXCLUDED.state, city = EXCLUDED.city,
  address = EXCLUDED.address, price_range = EXCLUDED.price_range, best_time = EXCLUDED.best_time,
  things_to_do = EXCLUDED.things_to_do, latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count, upvote_count = EXCLUDED.upvote_count;


UPDATE public.spots SET current_revision_id = '00000000-0110-0000-0000-00000000001a', approved_revision_id = '00000000-0110-0000-0000-00000000001a' WHERE id = '00000000-0100-0000-0000-00000000001a';

INSERT INTO public.published_spots (
  id, revision_id, name, category, description, state, city, address,
  price_range, best_time, things_to_do, image_path, latitude, longitude,
  rating_average, review_count, published_at, updated_at, upvote_count
) VALUES (
  '00000000-0100-0000-0000-00000000001a', '00000000-0110-0000-0000-00000000001a', 'Kuching Waterfront & Darul Hana Bridge', 'Urban', 'Scenic river esplanade featuring historic colonial landmarks, food kiosks, and the iconic S-shaped bridge.', 'Sarawak', 'Kuching', 'Jalan Main Bazaar, 93000 Kuching, Sarawak',
  '$', 'Sunset / Evening (5:30 PM - 9:30 PM)', 'Walk pedestrian Darul Hana Bridge, watch river musical fountain, take traditional tambang boat', NULL, 1.5594, 110.3444,
  4.7, 27, clock_timestamp() - interval '13 days', clock_timestamp() - interval '13 days', 48
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, category = EXCLUDED.category,
  description = EXCLUDED.description, state = EXCLUDED.state, city = EXCLUDED.city,
  address = EXCLUDED.address, price_range = EXCLUDED.price_range, best_time = EXCLUDED.best_time,
  things_to_do = EXCLUDED.things_to_do, latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count, upvote_count = EXCLUDED.upvote_count;


UPDATE public.spots SET current_revision_id = '00000000-0110-0000-0000-00000000001b', approved_revision_id = '00000000-0110-0000-0000-00000000001b' WHERE id = '00000000-0100-0000-0000-00000000001b';

INSERT INTO public.published_spots (
  id, revision_id, name, category, description, state, city, address,
  price_range, best_time, things_to_do, image_path, latitude, longitude,
  rating_average, review_count, published_at, updated_at, upvote_count
) VALUES (
  '00000000-0100-0000-0000-00000000001b', '00000000-0110-0000-0000-00000000001b', 'Gunung Mulu National Park', 'Nature', 'UNESCO World Heritage Site famed for colossal limestone caves, karst formations, and bat exodus flights.', 'Sarawak', 'Miri', 'Gunung Mulu National Park, No 11, Pejabat Pos Mulu, 98070 Mulu, Sarawak',
  '$$$', 'Morning cave walks & sunset bat exodus (5:00 PM)', 'Tour Deer Cave and Clearwater Cave, watch millions of bats exit at dusk, walk canopy skywalk', NULL, 4.0489, 114.8118,
  4.9, 31, clock_timestamp() - interval '12 days', clock_timestamp() - interval '12 days', 60
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, category = EXCLUDED.category,
  description = EXCLUDED.description, state = EXCLUDED.state, city = EXCLUDED.city,
  address = EXCLUDED.address, price_range = EXCLUDED.price_range, best_time = EXCLUDED.best_time,
  things_to_do = EXCLUDED.things_to_do, latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count, upvote_count = EXCLUDED.upvote_count;


UPDATE public.spots SET current_revision_id = '00000000-0110-0000-0000-00000000001c', approved_revision_id = '00000000-0110-0000-0000-00000000001c' WHERE id = '00000000-0100-0000-0000-00000000001c';

INSERT INTO public.published_spots (
  id, revision_id, name, category, description, state, city, address,
  price_range, best_time, things_to_do, image_path, latitude, longitude,
  rating_average, review_count, published_at, updated_at, upvote_count
) VALUES (
  '00000000-0100-0000-0000-00000000001c', '00000000-0110-0000-0000-00000000001c', 'Sultan Salahuddin Abdul Aziz Mosque (Blue Mosque)', 'Architecture', 'Malaysia''s largest mosque with an iconic blue and silver dome, towering minarets, and stained-glass halls.', 'Selangor', 'Shah Alam', 'Persiaran Masjid, Seksyen 14, 40000 Shah Alam, Selangor',
  '$', 'Morning or afternoon (guided tour)', 'Join free guided educational tour, admire Islamic decorative arts and calligraphy', NULL, 3.0784, 101.5208,
  4.7, 16, clock_timestamp() - interval '11 days', clock_timestamp() - interval '11 days', 24
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, category = EXCLUDED.category,
  description = EXCLUDED.description, state = EXCLUDED.state, city = EXCLUDED.city,
  address = EXCLUDED.address, price_range = EXCLUDED.price_range, best_time = EXCLUDED.best_time,
  things_to_do = EXCLUDED.things_to_do, latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count, upvote_count = EXCLUDED.upvote_count;


UPDATE public.spots SET current_revision_id = '00000000-0110-0000-0000-00000000001d', approved_revision_id = '00000000-0110-0000-0000-00000000001d' WHERE id = '00000000-0100-0000-0000-00000000001d';

INSERT INTO public.published_spots (
  id, revision_id, name, category, description, state, city, address,
  price_range, best_time, things_to_do, image_path, latitude, longitude,
  rating_average, review_count, published_at, updated_at, upvote_count
) VALUES (
  '00000000-0100-0000-0000-00000000001d', '00000000-0110-0000-0000-00000000001d', 'Kuala Selangor Nature Park (Taman Alam)', 'Nature', 'Protected coastal wetland habitat featuring mangrove boardwalks, bird hides, and silvered leaf monkeys.', 'Selangor', 'Kuala Selangor', 'Jalan Klinik, 45000 Kuala Selangor, Selangor',
  '$', 'Morning (8:00 AM - 11:00 AM)', 'Walk through mangrove boardwalk, observe migratory birds from watchtowers, see silvered leaf monkeys', NULL, 3.3396, 101.2464,
  4.4, 11, clock_timestamp() - interval '10 days', clock_timestamp() - interval '10 days', 15
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, category = EXCLUDED.category,
  description = EXCLUDED.description, state = EXCLUDED.state, city = EXCLUDED.city,
  address = EXCLUDED.address, price_range = EXCLUDED.price_range, best_time = EXCLUDED.best_time,
  things_to_do = EXCLUDED.things_to_do, latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count, upvote_count = EXCLUDED.upvote_count;


UPDATE public.spots SET current_revision_id = '00000000-0110-0000-0000-00000000001e', approved_revision_id = '00000000-0110-0000-0000-00000000001e' WHERE id = '00000000-0100-0000-0000-00000000001e';

INSERT INTO public.published_spots (
  id, revision_id, name, category, description, state, city, address,
  price_range, best_time, things_to_do, image_path, latitude, longitude,
  rating_average, review_count, published_at, updated_at, upvote_count
) VALUES (
  '00000000-0100-0000-0000-00000000001e', '00000000-0110-0000-0000-00000000001e', 'Boh Tea Estate Sungai Palas', 'Agriculture', 'Picturesque tea plantation nestled in the rolling hills with a futuristic tea cafe perched over the valley.', 'Pahang', 'Cameron Highlands', 'Sungai Palas Garden, 39100 Brinchang, Pahang',
  '$', 'Morning (8:30 AM - 11:30 AM)', 'Tour tea factory process, taste freshly brewed tea at cantilevered cafe, photograph rolling hills', NULL, 4.5173, 101.4005,
  4.7, 28, clock_timestamp() - interval '9 days', clock_timestamp() - interval '9 days', 49
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, category = EXCLUDED.category,
  description = EXCLUDED.description, state = EXCLUDED.state, city = EXCLUDED.city,
  address = EXCLUDED.address, price_range = EXCLUDED.price_range, best_time = EXCLUDED.best_time,
  things_to_do = EXCLUDED.things_to_do, latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count, upvote_count = EXCLUDED.upvote_count;


UPDATE public.spots SET current_revision_id = '00000000-0110-0000-0000-00000000001f', approved_revision_id = '00000000-0110-0000-0000-00000000001f' WHERE id = '00000000-0100-0000-0000-00000000001f';

INSERT INTO public.published_spots (
  id, revision_id, name, category, description, state, city, address,
  price_range, best_time, things_to_do, image_path, latitude, longitude,
  rating_average, review_count, published_at, updated_at, upvote_count
) VALUES (
  '00000000-0100-0000-0000-00000000001f', '00000000-0110-0000-0000-00000000001f', 'Mossy Forest', 'Nature', 'Enchanting high-altitude cloud forest draped in moss, ferns, orchids, and carnivorous pitcher plants.', 'Pahang', 'Cameron Highlands', 'Gunung Brinchang, 39000 Brinchang, Pahang',
  '$$', 'Morning (8:00 AM - 11:00 AM)', 'Walk elevated boardwalk through mist-shrouded mossy trees, observe rare montane orchids', NULL, 4.5238, 101.3824,
  4.6, 18, clock_timestamp() - interval '8 days', clock_timestamp() - interval '8 days', 30
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, category = EXCLUDED.category,
  description = EXCLUDED.description, state = EXCLUDED.state, city = EXCLUDED.city,
  address = EXCLUDED.address, price_range = EXCLUDED.price_range, best_time = EXCLUDED.best_time,
  things_to_do = EXCLUDED.things_to_do, latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count, upvote_count = EXCLUDED.upvote_count;


UPDATE public.spots SET current_revision_id = '00000000-0110-0000-0000-000000000020', approved_revision_id = '00000000-0110-0000-0000-000000000020' WHERE id = '00000000-0100-0000-0000-000000000020';

INSERT INTO public.published_spots (
  id, revision_id, name, category, description, state, city, address,
  price_range, best_time, things_to_do, image_path, latitude, longitude,
  rating_average, review_count, published_at, updated_at, upvote_count
) VALUES (
  '00000000-0100-0000-0000-000000000020', '00000000-0110-0000-0000-000000000020', 'Langkawi Sky Bridge & SkyCab', 'Engineering', 'Curved pedestrian cable-stayed bridge suspended 660 meters above sea level with sweeping Andaman Sea vistas.', 'Kedah', 'Langkawi', 'Oriental Village, Burau Bay, 07000 Langkawi, Kedah',
  '$$$', 'Morning (9:00 AM - 11:30 AM)', 'Ride SkyCab cable car, walk thrilling curved Sky Bridge, admire Andaman island archipelago', NULL, 6.3712, 99.6617,
  4.8, 30, clock_timestamp() - interval '7 days', clock_timestamp() - interval '7 days', 55
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, category = EXCLUDED.category,
  description = EXCLUDED.description, state = EXCLUDED.state, city = EXCLUDED.city,
  address = EXCLUDED.address, price_range = EXCLUDED.price_range, best_time = EXCLUDED.best_time,
  things_to_do = EXCLUDED.things_to_do, latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count, upvote_count = EXCLUDED.upvote_count;


UPDATE public.spots SET current_revision_id = '00000000-0110-0000-0000-000000000021', approved_revision_id = '00000000-0110-0000-0000-000000000021' WHERE id = '00000000-0100-0000-0000-000000000021';

INSERT INTO public.published_spots (
  id, revision_id, name, category, description, state, city, address,
  price_range, best_time, things_to_do, image_path, latitude, longitude,
  rating_average, review_count, published_at, updated_at, upvote_count
) VALUES (
  '00000000-0100-0000-0000-000000000021', '00000000-0110-0000-0000-000000000021', 'Islamic Heritage Park (Taman Tamadun Islam)', 'Heritage', 'Riverside monument park featuring intricate replicas of world Islamic landmarks and the Crystal Mosque.', 'Terengganu', 'Kuala Terengganu', 'Pulau Wan Man, 21000 Kuala Terengganu, Terengganu',
  '$$', 'Morning or late afternoon', 'Tour world monument replicas via tram, photograph Crystal Mosque by the Terengganu River', NULL, 5.3015, 103.1189,
  4.5, 13, clock_timestamp() - interval '6 days', clock_timestamp() - interval '6 days', 18
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, category = EXCLUDED.category,
  description = EXCLUDED.description, state = EXCLUDED.state, city = EXCLUDED.city,
  address = EXCLUDED.address, price_range = EXCLUDED.price_range, best_time = EXCLUDED.best_time,
  things_to_do = EXCLUDED.things_to_do, latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count, upvote_count = EXCLUDED.upvote_count;


UPDATE public.spots SET current_revision_id = '00000000-0110-0000-0000-000000000022', approved_revision_id = '00000000-0110-0000-0000-000000000022' WHERE id = '00000000-0100-0000-0000-000000000022';

INSERT INTO public.published_spots (
  id, revision_id, name, category, description, state, city, address,
  price_range, best_time, things_to_do, image_path, latitude, longitude,
  rating_average, review_count, published_at, updated_at, upvote_count
) VALUES (
  '00000000-0100-0000-0000-000000000022', '00000000-0110-0000-0000-000000000022', 'Tasik Kenyir (Kenyir Lake)', 'Nature', 'Largest man-made lake in Southeast Asia surrounded by tropical rainforest, waterfalls, and herbal islands.', 'Terengganu', 'Hulu Terengganu', 'Pengkalan Gawi, 21700 Kuala Berang, Terengganu',
  '$$', 'Full day excursion', 'Cruise lake to Lasir Waterfall, visit Kenyir Elephant Sanctuary, explore herbal garden island', NULL, 4.9667, 102.8167,
  4.6, 15, clock_timestamp() - interval '5 days', clock_timestamp() - interval '5 days', 22
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, category = EXCLUDED.category,
  description = EXCLUDED.description, state = EXCLUDED.state, city = EXCLUDED.city,
  address = EXCLUDED.address, price_range = EXCLUDED.price_range, best_time = EXCLUDED.best_time,
  things_to_do = EXCLUDED.things_to_do, latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count, upvote_count = EXCLUDED.upvote_count;

UPDATE public.spots SET current_revision_id = '00000000-0110-0000-0000-000000000023', approved_revision_id = NULL WHERE id = '00000000-0100-0000-0000-000000000023';
UPDATE public.spots SET current_revision_id = '00000000-0110-0000-0000-000000000024', approved_revision_id = NULL WHERE id = '00000000-0100-0000-0000-000000000024';
UPDATE public.spots SET current_revision_id = '00000000-0110-0000-0000-000000000025', approved_revision_id = NULL WHERE id = '00000000-0100-0000-0000-000000000025';

-- 2.1 RESTAURANTS (Base records)

INSERT INTO public.restaurants (id, owner_id, current_revision_id, approved_revision_id, moderation_version, ownership_status, created_at)
VALUES ('00000000-0200-0000-0000-000000000001', NULL, NULL, NULL, 1, 'unclaimed', clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.restaurants (id, owner_id, current_revision_id, approved_revision_id, moderation_version, ownership_status, created_at)
VALUES ('00000000-0200-0000-0000-000000000002', NULL, NULL, NULL, 1, 'unclaimed', clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.restaurants (id, owner_id, current_revision_id, approved_revision_id, moderation_version, ownership_status, created_at)
VALUES ('00000000-0200-0000-0000-000000000003', NULL, NULL, NULL, 1, 'unclaimed', clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.restaurants (id, owner_id, current_revision_id, approved_revision_id, moderation_version, ownership_status, created_at)
VALUES ('00000000-0200-0000-0000-000000000004', NULL, NULL, NULL, 1, 'unclaimed', clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.restaurants (id, owner_id, current_revision_id, approved_revision_id, moderation_version, ownership_status, created_at)
VALUES ('00000000-0200-0000-0000-000000000005', NULL, NULL, NULL, 1, 'unclaimed', clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.restaurants (id, owner_id, current_revision_id, approved_revision_id, moderation_version, ownership_status, created_at)
VALUES ('00000000-0200-0000-0000-000000000006', NULL, NULL, NULL, 1, 'unclaimed', clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.restaurants (id, owner_id, current_revision_id, approved_revision_id, moderation_version, ownership_status, created_at)
VALUES ('00000000-0200-0000-0000-000000000007', NULL, NULL, NULL, 1, 'unclaimed', clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.restaurants (id, owner_id, current_revision_id, approved_revision_id, moderation_version, ownership_status, created_at)
VALUES ('00000000-0200-0000-0000-000000000008', NULL, NULL, NULL, 1, 'unclaimed', clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.restaurants (id, owner_id, current_revision_id, approved_revision_id, moderation_version, ownership_status, created_at)
VALUES ('00000000-0200-0000-0000-000000000009', NULL, NULL, NULL, 1, 'unclaimed', clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.restaurants (id, owner_id, current_revision_id, approved_revision_id, moderation_version, ownership_status, created_at)
VALUES ('00000000-0200-0000-0000-00000000000a', NULL, NULL, NULL, 1, 'unclaimed', clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.restaurants (id, owner_id, current_revision_id, approved_revision_id, moderation_version, ownership_status, created_at)
VALUES ('00000000-0200-0000-0000-00000000000b', NULL, NULL, NULL, 1, 'unclaimed', clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.restaurants (id, owner_id, current_revision_id, approved_revision_id, moderation_version, ownership_status, created_at)
VALUES ('00000000-0200-0000-0000-00000000000c', NULL, NULL, NULL, 1, 'unclaimed', clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.restaurants (id, owner_id, current_revision_id, approved_revision_id, moderation_version, ownership_status, created_at)
VALUES ('00000000-0200-0000-0000-00000000000d', NULL, NULL, NULL, 1, 'unclaimed', clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.restaurants (id, owner_id, current_revision_id, approved_revision_id, moderation_version, ownership_status, created_at)
VALUES ('00000000-0200-0000-0000-00000000000e', NULL, NULL, NULL, 1, 'unclaimed', clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.restaurants (id, owner_id, current_revision_id, approved_revision_id, moderation_version, ownership_status, created_at)
VALUES ('00000000-0200-0000-0000-00000000000f', NULL, NULL, NULL, 1, 'unclaimed', clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.restaurants (id, owner_id, current_revision_id, approved_revision_id, moderation_version, ownership_status, created_at)
VALUES ('00000000-0200-0000-0000-000000000010', NULL, NULL, NULL, 1, 'unclaimed', clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.restaurants (id, owner_id, current_revision_id, approved_revision_id, moderation_version, ownership_status, created_at)
VALUES ('00000000-0200-0000-0000-000000000011', NULL, NULL, NULL, 1, 'unclaimed', clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.restaurants (id, owner_id, current_revision_id, approved_revision_id, moderation_version, ownership_status, created_at)
VALUES ('00000000-0200-0000-0000-000000000012', NULL, NULL, NULL, 1, 'unclaimed', clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.restaurants (id, owner_id, current_revision_id, approved_revision_id, moderation_version, ownership_status, created_at)
VALUES ('00000000-0200-0000-0000-000000000013', NULL, NULL, NULL, 1, 'unclaimed', clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.restaurants (id, owner_id, current_revision_id, approved_revision_id, moderation_version, ownership_status, created_at)
VALUES ('00000000-0200-0000-0000-000000000014', NULL, NULL, NULL, 1, 'unclaimed', clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.restaurants (id, owner_id, current_revision_id, approved_revision_id, moderation_version, ownership_status, created_at)
VALUES ('00000000-0200-0000-0000-000000000015', NULL, NULL, NULL, 1, 'unclaimed', clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.restaurants (id, owner_id, current_revision_id, approved_revision_id, moderation_version, ownership_status, created_at)
VALUES ('00000000-0200-0000-0000-000000000016', NULL, NULL, NULL, 1, 'unclaimed', clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.restaurants (id, owner_id, current_revision_id, approved_revision_id, moderation_version, ownership_status, created_at)
VALUES ('00000000-0200-0000-0000-000000000017', NULL, NULL, NULL, 1, 'unclaimed', clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.restaurants (id, owner_id, current_revision_id, approved_revision_id, moderation_version, ownership_status, created_at)
VALUES ('00000000-0200-0000-0000-000000000018', NULL, NULL, NULL, 1, 'unclaimed', clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.restaurants (id, owner_id, current_revision_id, approved_revision_id, moderation_version, ownership_status, created_at)
VALUES ('00000000-0200-0000-0000-000000000019', NULL, NULL, NULL, 1, 'unclaimed', clock_timestamp() - interval '30 days')
ON CONFLICT (id) DO NOTHING;


-- 2.2 RESTAURANT REVISIONS

INSERT INTO public.restaurant_revisions (
  id, restaurant_id, revision_number, author_id, status, name, address,
  state, city, cuisine_type, price_range, reviewed_dishes, social_media_url,
  cover_image_path, latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0210-0000-0000-000000000001', '00000000-0200-0000-0000-000000000001', 1, NULL, 'approved', 'Restoran Yut Kee', '1, Jalan Kamunting, Chow Kit, 50300 Kuala Lumpur',
  'Kuala Lumpur', 'Kuala Lumpur', 'Hainanese', '$', 'Roti Babi, Hainanese Pork Chop, Marble Cake, Kaya Toast', 'https://www.instagram.com/yutkeerestaurant',
  'https://images.unsplash.com/photo-1555396273-367ea4eb4db5', 3.1568, 101.6998,
  clock_timestamp() - interval '34 days', clock_timestamp() - interval '33 days',
  clock_timestamp() - interval '34 days', clock_timestamp() - interval '33 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, reviewed_dishes = EXCLUDED.reviewed_dishes, social_media_url = EXCLUDED.social_media_url, status = EXCLUDED.status;


INSERT INTO public.restaurant_revisions (
  id, restaurant_id, revision_number, author_id, status, name, address,
  state, city, cuisine_type, price_range, reviewed_dishes, social_media_url,
  cover_image_path, latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0210-0000-0000-000000000002', '00000000-0200-0000-0000-000000000002', 1, NULL, 'approved', 'Village Park Restaurant', '5, Jalan SS 21/37, Damansara Utama, 47400 Petaling Jaya, Selangor',
  'Selangor', 'Petaling Jaya', 'Malay / Nasi Lemak', '$', 'Nasi Lemak Ayam Goreng, Soto Ayam, Nasi Dagang', 'https://www.instagram.com/villageparkrestaurant',
  'https://images.unsplash.com/photo-1546069901-ba9599a7e63c', 3.1378, 101.6231,
  clock_timestamp() - interval '33 days', clock_timestamp() - interval '32 days',
  clock_timestamp() - interval '33 days', clock_timestamp() - interval '32 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, reviewed_dishes = EXCLUDED.reviewed_dishes, social_media_url = EXCLUDED.social_media_url, status = EXCLUDED.status;


INSERT INTO public.restaurant_revisions (
  id, restaurant_id, revision_number, author_id, status, name, address,
  state, city, cuisine_type, price_range, reviewed_dishes, social_media_url,
  cover_image_path, latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0210-0000-0000-000000000003', '00000000-0200-0000-0000-000000000003', 1, NULL, 'approved', 'Kim Lian Kee Restaurant', '49-51, Jalan Petaling, City Centre, 50000 Kuala Lumpur',
  'Kuala Lumpur', 'Kuala Lumpur', 'Chinese / Noodles', '$', 'Charcoal Fried Hokkien Mee, Moonlight Hor Fun, Fried Radish Cake', 'https://www.instagram.com/kimliankee',
  'https://images.unsplash.com/photo-1569718212165-3a8278d5f624', 3.1442, 101.6974,
  clock_timestamp() - interval '32 days', clock_timestamp() - interval '31 days',
  clock_timestamp() - interval '32 days', clock_timestamp() - interval '31 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, reviewed_dishes = EXCLUDED.reviewed_dishes, social_media_url = EXCLUDED.social_media_url, status = EXCLUDED.status;


INSERT INTO public.restaurant_revisions (
  id, restaurant_id, revision_number, author_id, status, name, address,
  state, city, cuisine_type, price_range, reviewed_dishes, social_media_url,
  cover_image_path, latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0210-0000-0000-000000000004', '00000000-0200-0000-0000-000000000004', 1, NULL, 'approved', 'Nasi Kandar Pelita (Ampang)', '149, Jalan Ampang, 50450 Kuala Lumpur',
  'Kuala Lumpur', 'Kuala Lumpur', 'Mamak / Indian Muslim', '$', 'Nasi Kandar Ayam Madu, Kuah Campur, Roti Canai, Teh Tarik', 'https://www.instagram.com/pelitanasikandar',
  'https://images.unsplash.com/photo-1589301760014-d929f3979dbc', 3.1592, 101.7118,
  clock_timestamp() - interval '31 days', clock_timestamp() - interval '30 days',
  clock_timestamp() - interval '31 days', clock_timestamp() - interval '30 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, reviewed_dishes = EXCLUDED.reviewed_dishes, social_media_url = EXCLUDED.social_media_url, status = EXCLUDED.status;


INSERT INTO public.restaurant_revisions (
  id, restaurant_id, revision_number, author_id, status, name, address,
  state, city, cuisine_type, price_range, reviewed_dishes, social_media_url,
  cover_image_path, latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0210-0000-0000-000000000005', '00000000-0200-0000-0000-000000000005', 1, NULL, 'approved', 'Hameediyah Restaurant', '164 A, Lebuh Campbell, 10100 George Town, Pulau Pinang',
  'Pulau Pinang', 'George Town', 'Nasi Kandar / Indian Muslim', '$', 'Nasi Kandar Kari Kepala Ikan, Murtabak Daging Special, Ayam Bawang', 'https://www.instagram.com/hameediyah',
  'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4', 5.4189, 100.3341,
  clock_timestamp() - interval '30 days', clock_timestamp() - interval '29 days',
  clock_timestamp() - interval '30 days', clock_timestamp() - interval '29 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, reviewed_dishes = EXCLUDED.reviewed_dishes, social_media_url = EXCLUDED.social_media_url, status = EXCLUDED.status;


INSERT INTO public.restaurant_revisions (
  id, restaurant_id, revision_number, author_id, status, name, address,
  state, city, cuisine_type, price_range, reviewed_dishes, social_media_url,
  cover_image_path, latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0210-0000-0000-000000000006', '00000000-0200-0000-0000-000000000006', 1, NULL, 'approved', 'Line Clear Nasi Kandar', '177, Jalan Penang, 10000 George Town, Pulau Pinang',
  'Pulau Pinang', 'George Town', 'Nasi Kandar / Street Food', '$', 'Nasi Kandar Sotong Goreng Besar, Kuah Banjir, Telur Sotong', 'https://www.instagram.com/lineclearnasikandar',
  'https://images.unsplash.com/photo-1552566626-52f8b828add9', 5.4198, 100.3323,
  clock_timestamp() - interval '29 days', clock_timestamp() - interval '28 days',
  clock_timestamp() - interval '29 days', clock_timestamp() - interval '28 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, reviewed_dishes = EXCLUDED.reviewed_dishes, social_media_url = EXCLUDED.social_media_url, status = EXCLUDED.status;


INSERT INTO public.restaurant_revisions (
  id, restaurant_id, revision_number, author_id, status, name, address,
  state, city, cuisine_type, price_range, reviewed_dishes, social_media_url,
  cover_image_path, latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0210-0000-0000-000000000007', '00000000-0200-0000-0000-000000000007', 1, NULL, 'approved', 'Tek Sen Restaurant', '18, Lebuh Carnarvon, 10100 George Town, Pulau Pinang',
  'Pulau Pinang', 'George Town', 'Cantonese / Zi Char', '$$', 'Double Roasted Pork with Chili Padi, Sambal Petai, Tu Poh Bean Curd', 'https://www.instagram.com/teksenrestaurant',
  'https://images.unsplash.com/photo-1543007630-9710e4a00a20', 5.4168, 100.3359,
  clock_timestamp() - interval '28 days', clock_timestamp() - interval '27 days',
  clock_timestamp() - interval '28 days', clock_timestamp() - interval '27 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, reviewed_dishes = EXCLUDED.reviewed_dishes, social_media_url = EXCLUDED.social_media_url, status = EXCLUDED.status;


INSERT INTO public.restaurant_revisions (
  id, restaurant_id, revision_number, author_id, status, name, address,
  state, city, cuisine_type, price_range, reviewed_dishes, social_media_url,
  cover_image_path, latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0210-0000-0000-000000000008', '00000000-0200-0000-0000-000000000008', 1, NULL, 'approved', 'Restoran Nyonya Makko', '123, Jalan Merdeka, Taman Melaka Raya, 75000 Melaka',
  'Melaka', 'Melaka', 'Peranakan / Nyonya', '$$', 'Ayam Pongteh, Udang Lemak Nenas, Sambal Belacan Kangkung, Cendol', 'https://www.instagram.com/makkonyonya',
  'https://images.unsplash.com/photo-1563245372-f21724e3856d', 2.1884, 102.2536,
  clock_timestamp() - interval '27 days', clock_timestamp() - interval '26 days',
  clock_timestamp() - interval '27 days', clock_timestamp() - interval '26 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, reviewed_dishes = EXCLUDED.reviewed_dishes, social_media_url = EXCLUDED.social_media_url, status = EXCLUDED.status;


INSERT INTO public.restaurant_revisions (
  id, restaurant_id, revision_number, author_id, status, name, address,
  state, city, cuisine_type, price_range, reviewed_dishes, social_media_url,
  cover_image_path, latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0210-0000-0000-000000000009', '00000000-0200-0000-0000-000000000009', 1, NULL, 'approved', 'Nancy''s Kitchen', '13, Jalan KL 3/8, Taman Kota Laksamana, 75200 Melaka',
  'Melaka', 'Melaka', 'Peranakan / Nyonya', '$', 'Nyonya Laksa, Popiah, Pie Tee, Sek Bak', 'https://www.instagram.com/eatatnancyskit',
  'https://images.unsplash.com/photo-1504674900247-0877df9cc836', 2.1979, 102.2415,
  clock_timestamp() - interval '26 days', clock_timestamp() - interval '25 days',
  clock_timestamp() - interval '26 days', clock_timestamp() - interval '25 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, reviewed_dishes = EXCLUDED.reviewed_dishes, social_media_url = EXCLUDED.social_media_url, status = EXCLUDED.status;


INSERT INTO public.restaurant_revisions (
  id, restaurant_id, revision_number, author_id, status, name, address,
  state, city, cuisine_type, price_range, reviewed_dishes, social_media_url,
  cover_image_path, latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0210-0000-0000-00000000000a', '00000000-0200-0000-0000-00000000000a', 1, NULL, 'approved', 'Chop Chung Wah', '20, Lorong Hang Jebat, 75200 Melaka',
  'Melaka', 'Melaka', 'Hainanese', '$', 'Hainanese Steamed Chicken, Hand-rolled Rice Balls, Chili Sauce', 'https://www.instagram.com/chopchungwah',
  'https://images.unsplash.com/photo-1512621776951-a57141f2eefd', 2.1947, 102.2483,
  clock_timestamp() - interval '25 days', clock_timestamp() - interval '24 days',
  clock_timestamp() - interval '25 days', clock_timestamp() - interval '24 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, reviewed_dishes = EXCLUDED.reviewed_dishes, social_media_url = EXCLUDED.social_media_url, status = EXCLUDED.status;


INSERT INTO public.restaurant_revisions (
  id, restaurant_id, revision_number, author_id, status, name, address,
  state, city, cuisine_type, price_range, reviewed_dishes, social_media_url,
  cover_image_path, latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0210-0000-0000-00000000000b', '00000000-0200-0000-0000-00000000000b', 1, NULL, 'approved', 'Restoran Thean Chun (House of Mirrors)', '73, Jalan Bandar Timah, 30000 Ipoh, Perak',
  'Perak', 'Ipoh', 'Chinese / Kopitiam', '$', 'Ipoh Shredded Chicken Hor Fun (Kai See Hor Fun), Pork Satay, Caramel Egg Custard', 'https://www.instagram.com/theanchunipoh',
  'https://images.unsplash.com/photo-1526318896980-cf78c088247c', 4.5962, 101.0776,
  clock_timestamp() - interval '24 days', clock_timestamp() - interval '23 days',
  clock_timestamp() - interval '24 days', clock_timestamp() - interval '23 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, reviewed_dishes = EXCLUDED.reviewed_dishes, social_media_url = EXCLUDED.social_media_url, status = EXCLUDED.status;


INSERT INTO public.restaurant_revisions (
  id, restaurant_id, revision_number, author_id, status, name, address,
  state, city, cuisine_type, price_range, reviewed_dishes, social_media_url,
  cover_image_path, latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0210-0000-0000-00000000000c', '00000000-0200-0000-0000-00000000000c', 1, NULL, 'approved', 'Restoran Lou Wong Tauge Ayam', '49, Jalan Yau Tet Shin, 30000 Ipoh, Perak',
  'Perak', 'Ipoh', 'Chinese / Street Food', '$', 'Ipoh Bean Sprout Chicken (Nga Choi Kai), Kuetiau Soup, Pork Meatballs', 'https://www.instagram.com/louwongipoh',
  'https://images.unsplash.com/photo-1565299585323-38d6b0865b47', 4.5937, 101.0841,
  clock_timestamp() - interval '23 days', clock_timestamp() - interval '22 days',
  clock_timestamp() - interval '23 days', clock_timestamp() - interval '22 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, reviewed_dishes = EXCLUDED.reviewed_dishes, social_media_url = EXCLUDED.social_media_url, status = EXCLUDED.status;


INSERT INTO public.restaurant_revisions (
  id, restaurant_id, revision_number, author_id, status, name, address,
  state, city, cuisine_type, price_range, reviewed_dishes, social_media_url,
  cover_image_path, latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0210-0000-0000-00000000000d', '00000000-0200-0000-0000-00000000000d', 1, NULL, 'approved', 'Sin Yoon Loong', '15A, Jalan Bandar Timah, 30000 Ipoh, Perak',
  'Perak', 'Ipoh', 'Hainanese / Kopitiam', '$', 'Original Ipoh White Coffee, Butter Kaya Toast, Soft Boiled Eggs, Dan Zhi', 'https://www.instagram.com/sinyoonloong',
  'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb', 4.5959, 101.0772,
  clock_timestamp() - interval '22 days', clock_timestamp() - interval '21 days',
  clock_timestamp() - interval '22 days', clock_timestamp() - interval '21 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, reviewed_dishes = EXCLUDED.reviewed_dishes, social_media_url = EXCLUDED.social_media_url, status = EXCLUDED.status;


INSERT INTO public.restaurant_revisions (
  id, restaurant_id, revision_number, author_id, status, name, address,
  state, city, cuisine_type, price_range, reviewed_dishes, social_media_url,
  cover_image_path, latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0210-0000-0000-00000000000e', '00000000-0200-0000-0000-00000000000e', 1, NULL, 'approved', 'Restoran Hua Mui', '131, Jalan Trus, Bandar Johor Bahru, 80000 Johor Bahru, Johor',
  'Johor', 'Johor Bahru', 'Hainanese', '$', 'Traditional Hainanese Chicken Chop, Butter Coffee, Fried Mee Hoon', 'https://www.instagram.com/restoranhuamui',
  'https://images.unsplash.com/photo-1555396273-367ea4eb4db5', 1.4573, 103.7642,
  clock_timestamp() - interval '21 days', clock_timestamp() - interval '20 days',
  clock_timestamp() - interval '21 days', clock_timestamp() - interval '20 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, reviewed_dishes = EXCLUDED.reviewed_dishes, social_media_url = EXCLUDED.social_media_url, status = EXCLUDED.status;


INSERT INTO public.restaurant_revisions (
  id, restaurant_id, revision_number, author_id, status, name, address,
  state, city, cuisine_type, price_range, reviewed_dishes, social_media_url,
  cover_image_path, latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0210-0000-0000-00000000000f', '00000000-0200-0000-0000-00000000000f', 1, NULL, 'approved', 'Hiap Joo Bakery & Biscuit Factory', '13, Jalan Tan Hiok Nee, Bandar Johor Bahru, 80000 Johor Bahru, Johor',
  'Johor', 'Johor Bahru', 'Bakery / Traditional', '$', 'Wood-fired Fresh Banana Cakes, Coconut Buns, Otak Buns', 'https://www.instagram.com/hiapjoobakery',
  'https://images.unsplash.com/photo-1509440159596-0249088772ff', 1.4566, 103.7648,
  clock_timestamp() - interval '20 days', clock_timestamp() - interval '19 days',
  clock_timestamp() - interval '20 days', clock_timestamp() - interval '19 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, reviewed_dishes = EXCLUDED.reviewed_dishes, social_media_url = EXCLUDED.social_media_url, status = EXCLUDED.status;


INSERT INTO public.restaurant_revisions (
  id, restaurant_id, revision_number, author_id, status, name, address,
  state, city, cuisine_type, price_range, reviewed_dishes, social_media_url,
  cover_image_path, latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0210-0000-0000-000000000010', '00000000-0200-0000-0000-000000000010', 1, NULL, 'approved', 'Kam Long Ah Zai Curry Fish Head', '74, Jalan Wong Ah Fook, Bandar Johor Bahru, 80000 Johor Bahru, Johor',
  'Johor', 'Johor Bahru', 'Chinese / Seafood', '$$', 'Claypot Red Snapper Curry Fish Head, Fried Bean Curd Skin, Tau Pok', 'https://www.instagram.com/kamlongahzai',
  'https://images.unsplash.com/photo-1544025162-d76694265947', 1.4589, 103.7645,
  clock_timestamp() - interval '19 days', clock_timestamp() - interval '18 days',
  clock_timestamp() - interval '19 days', clock_timestamp() - interval '18 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, reviewed_dishes = EXCLUDED.reviewed_dishes, social_media_url = EXCLUDED.social_media_url, status = EXCLUDED.status;


INSERT INTO public.restaurant_revisions (
  id, restaurant_id, revision_number, author_id, status, name, address,
  state, city, cuisine_type, price_range, reviewed_dishes, social_media_url,
  cover_image_path, latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0210-0000-0000-000000000011', '00000000-0200-0000-0000-000000000011', 1, NULL, 'approved', 'Kedai Kopi Yee Fung', '127, Jalan Gaya, Pusat Bandar Kota Kinabalu, 88000 Kota Kinabalu, Sabah',
  'Sabah', 'Kota Kinabalu', 'Sabah / Noodles', '$', 'Yee Fung Laksa, Ngau Chap (Beef Noodle Soup), Claypot Chicken Rice', 'https://www.instagram.com/yeefunglaksa',
  'https://images.unsplash.com/photo-1569718212165-3a8278d5f624', 5.9831, 116.0771,
  clock_timestamp() - interval '18 days', clock_timestamp() - interval '17 days',
  clock_timestamp() - interval '18 days', clock_timestamp() - interval '17 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, reviewed_dishes = EXCLUDED.reviewed_dishes, social_media_url = EXCLUDED.social_media_url, status = EXCLUDED.status;


INSERT INTO public.restaurant_revisions (
  id, restaurant_id, revision_number, author_id, status, name, address,
  state, city, cuisine_type, price_range, reviewed_dishes, social_media_url,
  cover_image_path, latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0210-0000-0000-000000000012', '00000000-0200-0000-0000-000000000012', 1, NULL, 'approved', 'Fatt Kee Seafood Restaurant (Hilltop)', 'Lot 18, Ground Floor, Beverly Hills Plaza, Jalan Bundusan, 88300 Kota Kinabalu, Sabah',
  'Sabah', 'Kota Kinabalu', 'Seafood / Noodles', '$$', 'Fresh Fish Head Soup Noodles, Tom Yam Fish Paste Noodles, Fried Fish Fillet', 'https://www.instagram.com/fattkeeseafood',
  'https://images.unsplash.com/photo-1534422298391-e4f8c172dddb', 5.9405, 116.0968,
  clock_timestamp() - interval '17 days', clock_timestamp() - interval '16 days',
  clock_timestamp() - interval '17 days', clock_timestamp() - interval '16 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, reviewed_dishes = EXCLUDED.reviewed_dishes, social_media_url = EXCLUDED.social_media_url, status = EXCLUDED.status;


INSERT INTO public.restaurant_revisions (
  id, restaurant_id, revision_number, author_id, status, name, address,
  state, city, cuisine_type, price_range, reviewed_dishes, social_media_url,
  cover_image_path, latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0210-0000-0000-000000000013', '00000000-0200-0000-0000-000000000013', 1, NULL, 'approved', 'Top Spot Food Court', 'Level 5, UTC Kuching, Jalan Bukit Mata Kuching, 93100 Kuching, Sarawak',
  'Sarawak', 'Kuching', 'Seafood / Local', '$$', 'Stir-fried Midin with Belacan, Butter Tiger Prawns, Crispy Oyster Pancake', 'https://www.instagram.com/topspotkuching',
  'https://images.unsplash.com/photo-1559847844-5315695dadae', 1.5562, 110.3541,
  clock_timestamp() - interval '16 days', clock_timestamp() - interval '15 days',
  clock_timestamp() - interval '16 days', clock_timestamp() - interval '15 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, reviewed_dishes = EXCLUDED.reviewed_dishes, social_media_url = EXCLUDED.social_media_url, status = EXCLUDED.status;


INSERT INTO public.restaurant_revisions (
  id, restaurant_id, revision_number, author_id, status, name, address,
  state, city, cuisine_type, price_range, reviewed_dishes, social_media_url,
  cover_image_path, latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0210-0000-0000-000000000014', '00000000-0200-0000-0000-000000000014', 1, NULL, 'approved', 'Choon Hui Cafe', '34, Jalan Ban Hock, 93100 Kuching, Sarawak',
  'Sarawak', 'Kuching', 'Sarawak / Kopitiam', '$', 'Sarawak Laksa (Anthony Bourdain recommended), Traditional Kolo Mee, Toast', 'https://www.instagram.com/choonhuicafe',
  'https://images.unsplash.com/photo-1569718212165-3a8278d5f624', 1.5517, 110.3546,
  clock_timestamp() - interval '15 days', clock_timestamp() - interval '14 days',
  clock_timestamp() - interval '15 days', clock_timestamp() - interval '14 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, reviewed_dishes = EXCLUDED.reviewed_dishes, social_media_url = EXCLUDED.social_media_url, status = EXCLUDED.status;


INSERT INTO public.restaurant_revisions (
  id, restaurant_id, revision_number, author_id, status, name, address,
  state, city, cuisine_type, price_range, reviewed_dishes, social_media_url,
  cover_image_path, latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0210-0000-0000-000000000015', '00000000-0200-0000-0000-000000000015', 1, NULL, 'approved', 'Restoran Kheng Pin', '80, Penang Road, 10000 George Town, Pulau Pinang',
  'Pulau Pinang', 'George Town', 'Hainanese / Street Food', '$', 'Hainanese Chicken Rice, Crispy Loh Bak, Prawn Fritters, Wan Tan Mee', 'https://www.instagram.com/khengpinpenang',
  'https://images.unsplash.com/photo-1565299585323-38d6b0865b47', 5.4194, 100.3326,
  clock_timestamp() - interval '14 days', clock_timestamp() - interval '13 days',
  clock_timestamp() - interval '14 days', clock_timestamp() - interval '13 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, reviewed_dishes = EXCLUDED.reviewed_dishes, social_media_url = EXCLUDED.social_media_url, status = EXCLUDED.status;


INSERT INTO public.restaurant_revisions (
  id, restaurant_id, revision_number, author_id, status, name, address,
  state, city, cuisine_type, price_range, reviewed_dishes, social_media_url,
  cover_image_path, latitude, longitude, submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0210-0000-0000-000000000016', '00000000-0200-0000-0000-000000000016', 1, NULL, 'approved', 'Capital Cafe', '213, Jalan Tuanku Abdul Rahman, City Centre, 50100 Kuala Lumpur',
  'Kuala Lumpur', 'Kuala Lumpur', 'Kopitiam / Multi-ethnic', '$', 'Mee Rebus, Rojak Mamak, Nasi Padang, Hainanese Hailam Coffee', 'https://www.instagram.com/capitalcafekl',
  'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb', 3.1554, 101.6967,
  clock_timestamp() - interval '13 days', clock_timestamp() - interval '12 days',
  clock_timestamp() - interval '13 days', clock_timestamp() - interval '12 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, reviewed_dishes = EXCLUDED.reviewed_dishes, social_media_url = EXCLUDED.social_media_url, status = EXCLUDED.status;


INSERT INTO public.restaurant_revisions (
  id, restaurant_id, revision_number, author_id, status, name, address,
  state, city, cuisine_type, price_range, reviewed_dishes, social_media_url,
  cover_image_path, latitude, longitude, submitted_at, created_at, updated_at
) VALUES (
  '00000000-0210-0000-0000-000000000017', '00000000-0200-0000-0000-000000000017', 1, NULL, 'submitted', 'Guan Heong Biscuit Shop', '160, Jalan Sultan Iskandar, 30000 Ipoh, Perak',
  'Perak', 'Ipoh', 'Bakery / Heritage', '$', 'Meat Floss Biscuit, Salted Egg Pastry, Heong Peah', 'https://www.instagram.com/guanheong',
  'https://images.unsplash.com/photo-1509440159596-0249088772ff', 4.5942, 101.0825,
  clock_timestamp() - interval '3 days', clock_timestamp() - interval '3 days', clock_timestamp() - interval '3 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, reviewed_dishes = EXCLUDED.reviewed_dishes, social_media_url = EXCLUDED.social_media_url, status = EXCLUDED.status;


INSERT INTO public.restaurant_revisions (
  id, restaurant_id, revision_number, author_id, status, name, address,
  state, city, cuisine_type, price_range, reviewed_dishes, social_media_url,
  cover_image_path, latitude, longitude, submitted_at, created_at, updated_at
) VALUES (
  '00000000-0210-0000-0000-000000000018', '00000000-0200-0000-0000-000000000018', 1, NULL, 'submitted', 'Ah Heng Duck Rice', '124, Lebuh Kimberly, 10100 George Town, Pulau Pinang',
  'Pulau Pinang', 'George Town', 'Chinese / Street Food', '$', 'Braised Duck Rice, Braised Eggs and Tofu, Kiam Chye Boey Soup', 'https://www.instagram.com/ahhengduckrice',
  'https://images.unsplash.com/photo-1569718212165-3a8278d5f624', 5.4162, 100.3332,
  clock_timestamp() - interval '3 days', clock_timestamp() - interval '3 days', clock_timestamp() - interval '3 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, reviewed_dishes = EXCLUDED.reviewed_dishes, social_media_url = EXCLUDED.social_media_url, status = EXCLUDED.status;


INSERT INTO public.restaurant_revisions (
  id, restaurant_id, revision_number, author_id, status, name, address,
  state, city, cuisine_type, price_range, reviewed_dishes, social_media_url,
  cover_image_path, latitude, longitude, submitted_at, created_at, updated_at
) VALUES (
  '00000000-0210-0000-0000-000000000019', '00000000-0200-0000-0000-000000000019', 1, NULL, 'submitted', 'Capitol Satay Celup', '41, Lorong Bukit Cina, Bandar Hilir, 75100 Melaka',
  'Melaka', 'Melaka', 'Street Food / Satay Celup', '$$', 'Satay Celup Skewers with Rich Peanut Gravy, Seafood, Fried Bean Curd', 'https://www.instagram.com/capitolsataycelup',
  'https://images.unsplash.com/photo-1555396273-367ea4eb4db5', 2.1965, 102.2512,
  clock_timestamp() - interval '3 days', clock_timestamp() - interval '3 days', clock_timestamp() - interval '3 days'
) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, reviewed_dishes = EXCLUDED.reviewed_dishes, social_media_url = EXCLUDED.social_media_url, status = EXCLUDED.status;


-- 2.3 PUBLISHED RESTAURANTS & RESTAURANTS POINTER UPDATES

UPDATE public.restaurants SET current_revision_id = '00000000-0210-0000-0000-000000000001', approved_revision_id = '00000000-0210-0000-0000-000000000001' WHERE id = '00000000-0200-0000-0000-000000000001';

INSERT INTO public.published_restaurants (
  id, revision_id, name, address, state, city, cuisine_type, price_range,
  reviewed_dishes, social_media_url, cover_image_path, creator_display_name,
  ownership_status, latitude, longitude, rating_average, review_count,
  published_at, updated_at, social_link_status
) VALUES (
  '00000000-0200-0000-0000-000000000001', '00000000-0210-0000-0000-000000000001', 'Restoran Yut Kee', '1, Jalan Kamunting, Chow Kit, 50300 Kuala Lumpur', 'Kuala Lumpur', 'Kuala Lumpur', 'Hainanese', '$',
  'Roti Babi, Hainanese Pork Chop, Marble Cake, Kaya Toast', 'https://www.instagram.com/yutkeerestaurant', 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5', 'Uncle Jack',
  'unclaimed', 3.1568, 101.6998, 4.6, 28,
  clock_timestamp() - interval '33 days', clock_timestamp() - interval '33 days', 'active'
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, address = EXCLUDED.address,
  state = EXCLUDED.state, city = EXCLUDED.city, cuisine_type = EXCLUDED.cuisine_type,
  price_range = EXCLUDED.price_range, reviewed_dishes = EXCLUDED.reviewed_dishes,
  social_media_url = EXCLUDED.social_media_url, cover_image_path = EXCLUDED.cover_image_path,
  latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count;


UPDATE public.restaurants SET current_revision_id = '00000000-0210-0000-0000-000000000002', approved_revision_id = '00000000-0210-0000-0000-000000000002' WHERE id = '00000000-0200-0000-0000-000000000002';

INSERT INTO public.published_restaurants (
  id, revision_id, name, address, state, city, cuisine_type, price_range,
  reviewed_dishes, social_media_url, cover_image_path, creator_display_name,
  ownership_status, latitude, longitude, rating_average, review_count,
  published_at, updated_at, social_link_status
) VALUES (
  '00000000-0200-0000-0000-000000000002', '00000000-0210-0000-0000-000000000002', 'Village Park Restaurant', '5, Jalan SS 21/37, Damansara Utama, 47400 Petaling Jaya, Selangor', 'Selangor', 'Petaling Jaya', 'Malay / Nasi Lemak', '$',
  'Nasi Lemak Ayam Goreng, Soto Ayam, Nasi Dagang', 'https://www.instagram.com/villageparkrestaurant', 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c', 'Chef Shahril',
  'unclaimed', 3.1378, 101.6231, 4.8, 35,
  clock_timestamp() - interval '32 days', clock_timestamp() - interval '32 days', 'active'
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, address = EXCLUDED.address,
  state = EXCLUDED.state, city = EXCLUDED.city, cuisine_type = EXCLUDED.cuisine_type,
  price_range = EXCLUDED.price_range, reviewed_dishes = EXCLUDED.reviewed_dishes,
  social_media_url = EXCLUDED.social_media_url, cover_image_path = EXCLUDED.cover_image_path,
  latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count;


UPDATE public.restaurants SET current_revision_id = '00000000-0210-0000-0000-000000000003', approved_revision_id = '00000000-0210-0000-0000-000000000003' WHERE id = '00000000-0200-0000-0000-000000000003';

INSERT INTO public.published_restaurants (
  id, revision_id, name, address, state, city, cuisine_type, price_range,
  reviewed_dishes, social_media_url, cover_image_path, creator_display_name,
  ownership_status, latitude, longitude, rating_average, review_count,
  published_at, updated_at, social_link_status
) VALUES (
  '00000000-0200-0000-0000-000000000003', '00000000-0210-0000-0000-000000000003', 'Kim Lian Kee Restaurant', '49-51, Jalan Petaling, City Centre, 50000 Kuala Lumpur', 'Kuala Lumpur', 'Kuala Lumpur', 'Chinese / Noodles', '$',
  'Charcoal Fried Hokkien Mee, Moonlight Hor Fun, Fried Radish Cake', 'https://www.instagram.com/kimliankee', 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624', 'Lee Family',
  'unclaimed', 3.1442, 101.6974, 4.5, 24,
  clock_timestamp() - interval '31 days', clock_timestamp() - interval '31 days', 'active'
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, address = EXCLUDED.address,
  state = EXCLUDED.state, city = EXCLUDED.city, cuisine_type = EXCLUDED.cuisine_type,
  price_range = EXCLUDED.price_range, reviewed_dishes = EXCLUDED.reviewed_dishes,
  social_media_url = EXCLUDED.social_media_url, cover_image_path = EXCLUDED.cover_image_path,
  latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count;


UPDATE public.restaurants SET current_revision_id = '00000000-0210-0000-0000-000000000004', approved_revision_id = '00000000-0210-0000-0000-000000000004' WHERE id = '00000000-0200-0000-0000-000000000004';

INSERT INTO public.published_restaurants (
  id, revision_id, name, address, state, city, cuisine_type, price_range,
  reviewed_dishes, social_media_url, cover_image_path, creator_display_name,
  ownership_status, latitude, longitude, rating_average, review_count,
  published_at, updated_at, social_link_status
) VALUES (
  '00000000-0200-0000-0000-000000000004', '00000000-0210-0000-0000-000000000004', 'Nasi Kandar Pelita (Ampang)', '149, Jalan Ampang, 50450 Kuala Lumpur', 'Kuala Lumpur', 'Kuala Lumpur', 'Mamak / Indian Muslim', '$',
  'Nasi Kandar Ayam Madu, Kuah Campur, Roti Canai, Teh Tarik', 'https://www.instagram.com/pelitanasikandar', 'https://images.unsplash.com/photo-1589301760014-d929f3979dbc', 'Pelita Team',
  'unclaimed', 3.1592, 101.7118, 4.4, 20,
  clock_timestamp() - interval '30 days', clock_timestamp() - interval '30 days', 'active'
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, address = EXCLUDED.address,
  state = EXCLUDED.state, city = EXCLUDED.city, cuisine_type = EXCLUDED.cuisine_type,
  price_range = EXCLUDED.price_range, reviewed_dishes = EXCLUDED.reviewed_dishes,
  social_media_url = EXCLUDED.social_media_url, cover_image_path = EXCLUDED.cover_image_path,
  latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count;


UPDATE public.restaurants SET current_revision_id = '00000000-0210-0000-0000-000000000005', approved_revision_id = '00000000-0210-0000-0000-000000000005' WHERE id = '00000000-0200-0000-0000-000000000005';

INSERT INTO public.published_restaurants (
  id, revision_id, name, address, state, city, cuisine_type, price_range,
  reviewed_dishes, social_media_url, cover_image_path, creator_display_name,
  ownership_status, latitude, longitude, rating_average, review_count,
  published_at, updated_at, social_link_status
) VALUES (
  '00000000-0200-0000-0000-000000000005', '00000000-0210-0000-0000-000000000005', 'Hameediyah Restaurant', '164 A, Lebuh Campbell, 10100 George Town, Pulau Pinang', 'Pulau Pinang', 'George Town', 'Nasi Kandar / Indian Muslim', '$',
  'Nasi Kandar Kari Kepala Ikan, Murtabak Daging Special, Ayam Bawang', 'https://www.instagram.com/hameediyah', 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4', 'Syed Family',
  'unclaimed', 5.4189, 100.3341, 4.7, 32,
  clock_timestamp() - interval '29 days', clock_timestamp() - interval '29 days', 'active'
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, address = EXCLUDED.address,
  state = EXCLUDED.state, city = EXCLUDED.city, cuisine_type = EXCLUDED.cuisine_type,
  price_range = EXCLUDED.price_range, reviewed_dishes = EXCLUDED.reviewed_dishes,
  social_media_url = EXCLUDED.social_media_url, cover_image_path = EXCLUDED.cover_image_path,
  latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count;


UPDATE public.restaurants SET current_revision_id = '00000000-0210-0000-0000-000000000006', approved_revision_id = '00000000-0210-0000-0000-000000000006' WHERE id = '00000000-0200-0000-0000-000000000006';

INSERT INTO public.published_restaurants (
  id, revision_id, name, address, state, city, cuisine_type, price_range,
  reviewed_dishes, social_media_url, cover_image_path, creator_display_name,
  ownership_status, latitude, longitude, rating_average, review_count,
  published_at, updated_at, social_link_status
) VALUES (
  '00000000-0200-0000-0000-000000000006', '00000000-0210-0000-0000-000000000006', 'Line Clear Nasi Kandar', '177, Jalan Penang, 10000 George Town, Pulau Pinang', 'Pulau Pinang', 'George Town', 'Nasi Kandar / Street Food', '$',
  'Nasi Kandar Sotong Goreng Besar, Kuah Banjir, Telur Sotong', 'https://www.instagram.com/lineclearnasikandar', 'https://images.unsplash.com/photo-1552566626-52f8b828add9', 'Pak Cik Line Clear',
  'unclaimed', 5.4198, 100.3323, 4.5, 26,
  clock_timestamp() - interval '28 days', clock_timestamp() - interval '28 days', 'active'
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, address = EXCLUDED.address,
  state = EXCLUDED.state, city = EXCLUDED.city, cuisine_type = EXCLUDED.cuisine_type,
  price_range = EXCLUDED.price_range, reviewed_dishes = EXCLUDED.reviewed_dishes,
  social_media_url = EXCLUDED.social_media_url, cover_image_path = EXCLUDED.cover_image_path,
  latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count;


UPDATE public.restaurants SET current_revision_id = '00000000-0210-0000-0000-000000000007', approved_revision_id = '00000000-0210-0000-0000-000000000007' WHERE id = '00000000-0200-0000-0000-000000000007';

INSERT INTO public.published_restaurants (
  id, revision_id, name, address, state, city, cuisine_type, price_range,
  reviewed_dishes, social_media_url, cover_image_path, creator_display_name,
  ownership_status, latitude, longitude, rating_average, review_count,
  published_at, updated_at, social_link_status
) VALUES (
  '00000000-0200-0000-0000-000000000007', '00000000-0210-0000-0000-000000000007', 'Tek Sen Restaurant', '18, Lebuh Carnarvon, 10100 George Town, Pulau Pinang', 'Pulau Pinang', 'George Town', 'Cantonese / Zi Char', '$$',
  'Double Roasted Pork with Chili Padi, Sambal Petai, Tu Poh Bean Curd', 'https://www.instagram.com/teksenrestaurant', 'https://images.unsplash.com/photo-1543007630-9710e4a00a20', 'Tek Sen Family',
  'unclaimed', 5.4168, 100.3359, 4.7, 25,
  clock_timestamp() - interval '27 days', clock_timestamp() - interval '27 days', 'active'
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, address = EXCLUDED.address,
  state = EXCLUDED.state, city = EXCLUDED.city, cuisine_type = EXCLUDED.cuisine_type,
  price_range = EXCLUDED.price_range, reviewed_dishes = EXCLUDED.reviewed_dishes,
  social_media_url = EXCLUDED.social_media_url, cover_image_path = EXCLUDED.cover_image_path,
  latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count;


UPDATE public.restaurants SET current_revision_id = '00000000-0210-0000-0000-000000000008', approved_revision_id = '00000000-0210-0000-0000-000000000008' WHERE id = '00000000-0200-0000-0000-000000000008';

INSERT INTO public.published_restaurants (
  id, revision_id, name, address, state, city, cuisine_type, price_range,
  reviewed_dishes, social_media_url, cover_image_path, creator_display_name,
  ownership_status, latitude, longitude, rating_average, review_count,
  published_at, updated_at, social_link_status
) VALUES (
  '00000000-0200-0000-0000-000000000008', '00000000-0210-0000-0000-000000000008', 'Restoran Nyonya Makko', '123, Jalan Merdeka, Taman Melaka Raya, 75000 Melaka', 'Melaka', 'Melaka', 'Peranakan / Nyonya', '$$',
  'Ayam Pongteh, Udang Lemak Nenas, Sambal Belacan Kangkung, Cendol', 'https://www.instagram.com/makkonyonya', 'https://images.unsplash.com/photo-1563245372-f21724e3856d', 'Makko Kitchen',
  'unclaimed', 2.1884, 102.2536, 4.6, 22,
  clock_timestamp() - interval '26 days', clock_timestamp() - interval '26 days', 'active'
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, address = EXCLUDED.address,
  state = EXCLUDED.state, city = EXCLUDED.city, cuisine_type = EXCLUDED.cuisine_type,
  price_range = EXCLUDED.price_range, reviewed_dishes = EXCLUDED.reviewed_dishes,
  social_media_url = EXCLUDED.social_media_url, cover_image_path = EXCLUDED.cover_image_path,
  latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count;


UPDATE public.restaurants SET current_revision_id = '00000000-0210-0000-0000-000000000009', approved_revision_id = '00000000-0210-0000-0000-000000000009' WHERE id = '00000000-0200-0000-0000-000000000009';

INSERT INTO public.published_restaurants (
  id, revision_id, name, address, state, city, cuisine_type, price_range,
  reviewed_dishes, social_media_url, cover_image_path, creator_display_name,
  ownership_status, latitude, longitude, rating_average, review_count,
  published_at, updated_at, social_link_status
) VALUES (
  '00000000-0200-0000-0000-000000000009', '00000000-0210-0000-0000-000000000009', 'Nancy''s Kitchen', '13, Jalan KL 3/8, Taman Kota Laksamana, 75200 Melaka', 'Melaka', 'Melaka', 'Peranakan / Nyonya', '$',
  'Nyonya Laksa, Popiah, Pie Tee, Sek Bak', 'https://www.instagram.com/eatatnancyskit', 'https://images.unsplash.com/photo-1504674900247-0877df9cc836', 'Nancy Lim',
  'unclaimed', 2.1979, 102.2415, 4.7, 30,
  clock_timestamp() - interval '25 days', clock_timestamp() - interval '25 days', 'active'
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, address = EXCLUDED.address,
  state = EXCLUDED.state, city = EXCLUDED.city, cuisine_type = EXCLUDED.cuisine_type,
  price_range = EXCLUDED.price_range, reviewed_dishes = EXCLUDED.reviewed_dishes,
  social_media_url = EXCLUDED.social_media_url, cover_image_path = EXCLUDED.cover_image_path,
  latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count;


UPDATE public.restaurants SET current_revision_id = '00000000-0210-0000-0000-00000000000a', approved_revision_id = '00000000-0210-0000-0000-00000000000a' WHERE id = '00000000-0200-0000-0000-00000000000a';

INSERT INTO public.published_restaurants (
  id, revision_id, name, address, state, city, cuisine_type, price_range,
  reviewed_dishes, social_media_url, cover_image_path, creator_display_name,
  ownership_status, latitude, longitude, rating_average, review_count,
  published_at, updated_at, social_link_status
) VALUES (
  '00000000-0200-0000-0000-00000000000a', '00000000-0210-0000-0000-00000000000a', 'Chop Chung Wah', '20, Lorong Hang Jebat, 75200 Melaka', 'Melaka', 'Melaka', 'Hainanese', '$',
  'Hainanese Steamed Chicken, Hand-rolled Rice Balls, Chili Sauce', 'https://www.instagram.com/chopchungwah', 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd', 'Uncle Chung',
  'unclaimed', 2.1947, 102.2483, 4.4, 21,
  clock_timestamp() - interval '24 days', clock_timestamp() - interval '24 days', 'active'
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, address = EXCLUDED.address,
  state = EXCLUDED.state, city = EXCLUDED.city, cuisine_type = EXCLUDED.cuisine_type,
  price_range = EXCLUDED.price_range, reviewed_dishes = EXCLUDED.reviewed_dishes,
  social_media_url = EXCLUDED.social_media_url, cover_image_path = EXCLUDED.cover_image_path,
  latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count;


UPDATE public.restaurants SET current_revision_id = '00000000-0210-0000-0000-00000000000b', approved_revision_id = '00000000-0210-0000-0000-00000000000b' WHERE id = '00000000-0200-0000-0000-00000000000b';

INSERT INTO public.published_restaurants (
  id, revision_id, name, address, state, city, cuisine_type, price_range,
  reviewed_dishes, social_media_url, cover_image_path, creator_display_name,
  ownership_status, latitude, longitude, rating_average, review_count,
  published_at, updated_at, social_link_status
) VALUES (
  '00000000-0200-0000-0000-00000000000b', '00000000-0210-0000-0000-00000000000b', 'Restoran Thean Chun (House of Mirrors)', '73, Jalan Bandar Timah, 30000 Ipoh, Perak', 'Perak', 'Ipoh', 'Chinese / Kopitiam', '$',
  'Ipoh Shredded Chicken Hor Fun (Kai See Hor Fun), Pork Satay, Caramel Egg Custard', 'https://www.instagram.com/theanchunipoh', 'https://images.unsplash.com/photo-1526318896980-cf78c088247c', 'Thean Chun Kopitiam',
  'unclaimed', 4.5962, 101.0776, 4.7, 34,
  clock_timestamp() - interval '23 days', clock_timestamp() - interval '23 days', 'active'
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, address = EXCLUDED.address,
  state = EXCLUDED.state, city = EXCLUDED.city, cuisine_type = EXCLUDED.cuisine_type,
  price_range = EXCLUDED.price_range, reviewed_dishes = EXCLUDED.reviewed_dishes,
  social_media_url = EXCLUDED.social_media_url, cover_image_path = EXCLUDED.cover_image_path,
  latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count;


UPDATE public.restaurants SET current_revision_id = '00000000-0210-0000-0000-00000000000c', approved_revision_id = '00000000-0210-0000-0000-00000000000c' WHERE id = '00000000-0200-0000-0000-00000000000c';

INSERT INTO public.published_restaurants (
  id, revision_id, name, address, state, city, cuisine_type, price_range,
  reviewed_dishes, social_media_url, cover_image_path, creator_display_name,
  ownership_status, latitude, longitude, rating_average, review_count,
  published_at, updated_at, social_link_status
) VALUES (
  '00000000-0200-0000-0000-00000000000c', '00000000-0210-0000-0000-00000000000c', 'Restoran Lou Wong Tauge Ayam', '49, Jalan Yau Tet Shin, 30000 Ipoh, Perak', 'Perak', 'Ipoh', 'Chinese / Street Food', '$',
  'Ipoh Bean Sprout Chicken (Nga Choi Kai), Kuetiau Soup, Pork Meatballs', 'https://www.instagram.com/louwongipoh', 'https://images.unsplash.com/photo-1565299585323-38d6b0865b47', 'Lou Wong Team',
  'unclaimed', 4.5937, 101.0841, 4.5, 27,
  clock_timestamp() - interval '22 days', clock_timestamp() - interval '22 days', 'active'
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, address = EXCLUDED.address,
  state = EXCLUDED.state, city = EXCLUDED.city, cuisine_type = EXCLUDED.cuisine_type,
  price_range = EXCLUDED.price_range, reviewed_dishes = EXCLUDED.reviewed_dishes,
  social_media_url = EXCLUDED.social_media_url, cover_image_path = EXCLUDED.cover_image_path,
  latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count;


UPDATE public.restaurants SET current_revision_id = '00000000-0210-0000-0000-00000000000d', approved_revision_id = '00000000-0210-0000-0000-00000000000d' WHERE id = '00000000-0200-0000-0000-00000000000d';

INSERT INTO public.published_restaurants (
  id, revision_id, name, address, state, city, cuisine_type, price_range,
  reviewed_dishes, social_media_url, cover_image_path, creator_display_name,
  ownership_status, latitude, longitude, rating_average, review_count,
  published_at, updated_at, social_link_status
) VALUES (
  '00000000-0200-0000-0000-00000000000d', '00000000-0210-0000-0000-00000000000d', 'Sin Yoon Loong', '15A, Jalan Bandar Timah, 30000 Ipoh, Perak', 'Perak', 'Ipoh', 'Hainanese / Kopitiam', '$',
  'Original Ipoh White Coffee, Butter Kaya Toast, Soft Boiled Eggs, Dan Zhi', 'https://www.instagram.com/sinyoonloong', 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb', 'Sin Yoon Loong Pioneer',
  'unclaimed', 4.5959, 101.0772, 4.6, 29,
  clock_timestamp() - interval '21 days', clock_timestamp() - interval '21 days', 'active'
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, address = EXCLUDED.address,
  state = EXCLUDED.state, city = EXCLUDED.city, cuisine_type = EXCLUDED.cuisine_type,
  price_range = EXCLUDED.price_range, reviewed_dishes = EXCLUDED.reviewed_dishes,
  social_media_url = EXCLUDED.social_media_url, cover_image_path = EXCLUDED.cover_image_path,
  latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count;


UPDATE public.restaurants SET current_revision_id = '00000000-0210-0000-0000-00000000000e', approved_revision_id = '00000000-0210-0000-0000-00000000000e' WHERE id = '00000000-0200-0000-0000-00000000000e';

INSERT INTO public.published_restaurants (
  id, revision_id, name, address, state, city, cuisine_type, price_range,
  reviewed_dishes, social_media_url, cover_image_path, creator_display_name,
  ownership_status, latitude, longitude, rating_average, review_count,
  published_at, updated_at, social_link_status
) VALUES (
  '00000000-0200-0000-0000-00000000000e', '00000000-0210-0000-0000-00000000000e', 'Restoran Hua Mui', '131, Jalan Trus, Bandar Johor Bahru, 80000 Johor Bahru, Johor', 'Johor', 'Johor Bahru', 'Hainanese', '$',
  'Traditional Hainanese Chicken Chop, Butter Coffee, Fried Mee Hoon', 'https://www.instagram.com/restoranhuamui', 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5', 'Hua Mui Founders',
  'unclaimed', 1.4573, 103.7642, 4.6, 23,
  clock_timestamp() - interval '20 days', clock_timestamp() - interval '20 days', 'active'
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, address = EXCLUDED.address,
  state = EXCLUDED.state, city = EXCLUDED.city, cuisine_type = EXCLUDED.cuisine_type,
  price_range = EXCLUDED.price_range, reviewed_dishes = EXCLUDED.reviewed_dishes,
  social_media_url = EXCLUDED.social_media_url, cover_image_path = EXCLUDED.cover_image_path,
  latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count;


UPDATE public.restaurants SET current_revision_id = '00000000-0210-0000-0000-00000000000f', approved_revision_id = '00000000-0210-0000-0000-00000000000f' WHERE id = '00000000-0200-0000-0000-00000000000f';

INSERT INTO public.published_restaurants (
  id, revision_id, name, address, state, city, cuisine_type, price_range,
  reviewed_dishes, social_media_url, cover_image_path, creator_display_name,
  ownership_status, latitude, longitude, rating_average, review_count,
  published_at, updated_at, social_link_status
) VALUES (
  '00000000-0200-0000-0000-00000000000f', '00000000-0210-0000-0000-00000000000f', 'Hiap Joo Bakery & Biscuit Factory', '13, Jalan Tan Hiok Nee, Bandar Johor Bahru, 80000 Johor Bahru, Johor', 'Johor', 'Johor Bahru', 'Bakery / Traditional', '$',
  'Wood-fired Fresh Banana Cakes, Coconut Buns, Otak Buns', 'https://www.instagram.com/hiapjoobakery', 'https://images.unsplash.com/photo-1509440159596-0249088772ff', 'Lim Family (Est 1919)',
  'unclaimed', 1.4566, 103.7648, 4.8, 38,
  clock_timestamp() - interval '19 days', clock_timestamp() - interval '19 days', 'active'
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, address = EXCLUDED.address,
  state = EXCLUDED.state, city = EXCLUDED.city, cuisine_type = EXCLUDED.cuisine_type,
  price_range = EXCLUDED.price_range, reviewed_dishes = EXCLUDED.reviewed_dishes,
  social_media_url = EXCLUDED.social_media_url, cover_image_path = EXCLUDED.cover_image_path,
  latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count;


UPDATE public.restaurants SET current_revision_id = '00000000-0210-0000-0000-000000000010', approved_revision_id = '00000000-0210-0000-0000-000000000010' WHERE id = '00000000-0200-0000-0000-000000000010';

INSERT INTO public.published_restaurants (
  id, revision_id, name, address, state, city, cuisine_type, price_range,
  reviewed_dishes, social_media_url, cover_image_path, creator_display_name,
  ownership_status, latitude, longitude, rating_average, review_count,
  published_at, updated_at, social_link_status
) VALUES (
  '00000000-0200-0000-0000-000000000010', '00000000-0210-0000-0000-000000000010', 'Kam Long Ah Zai Curry Fish Head', '74, Jalan Wong Ah Fook, Bandar Johor Bahru, 80000 Johor Bahru, Johor', 'Johor', 'Johor Bahru', 'Chinese / Seafood', '$$',
  'Claypot Red Snapper Curry Fish Head, Fried Bean Curd Skin, Tau Pok', 'https://www.instagram.com/kamlongahzai', 'https://images.unsplash.com/photo-1544025162-d76694265947', 'Ah Zai',
  'unclaimed', 1.4589, 103.7645, 4.6, 25,
  clock_timestamp() - interval '18 days', clock_timestamp() - interval '18 days', 'active'
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, address = EXCLUDED.address,
  state = EXCLUDED.state, city = EXCLUDED.city, cuisine_type = EXCLUDED.cuisine_type,
  price_range = EXCLUDED.price_range, reviewed_dishes = EXCLUDED.reviewed_dishes,
  social_media_url = EXCLUDED.social_media_url, cover_image_path = EXCLUDED.cover_image_path,
  latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count;


UPDATE public.restaurants SET current_revision_id = '00000000-0210-0000-0000-000000000011', approved_revision_id = '00000000-0210-0000-0000-000000000011' WHERE id = '00000000-0200-0000-0000-000000000011';

INSERT INTO public.published_restaurants (
  id, revision_id, name, address, state, city, cuisine_type, price_range,
  reviewed_dishes, social_media_url, cover_image_path, creator_display_name,
  ownership_status, latitude, longitude, rating_average, review_count,
  published_at, updated_at, social_link_status
) VALUES (
  '00000000-0200-0000-0000-000000000011', '00000000-0210-0000-0000-000000000011', 'Kedai Kopi Yee Fung', '127, Jalan Gaya, Pusat Bandar Kota Kinabalu, 88000 Kota Kinabalu, Sabah', 'Sabah', 'Kota Kinabalu', 'Sabah / Noodles', '$',
  'Yee Fung Laksa, Ngau Chap (Beef Noodle Soup), Claypot Chicken Rice', 'https://www.instagram.com/yeefunglaksa', 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624', 'Yee Fung Kitchen',
  'unclaimed', 5.9831, 116.0771, 4.7, 31,
  clock_timestamp() - interval '17 days', clock_timestamp() - interval '17 days', 'active'
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, address = EXCLUDED.address,
  state = EXCLUDED.state, city = EXCLUDED.city, cuisine_type = EXCLUDED.cuisine_type,
  price_range = EXCLUDED.price_range, reviewed_dishes = EXCLUDED.reviewed_dishes,
  social_media_url = EXCLUDED.social_media_url, cover_image_path = EXCLUDED.cover_image_path,
  latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count;


UPDATE public.restaurants SET current_revision_id = '00000000-0210-0000-0000-000000000012', approved_revision_id = '00000000-0210-0000-0000-000000000012' WHERE id = '00000000-0200-0000-0000-000000000012';

INSERT INTO public.published_restaurants (
  id, revision_id, name, address, state, city, cuisine_type, price_range,
  reviewed_dishes, social_media_url, cover_image_path, creator_display_name,
  ownership_status, latitude, longitude, rating_average, review_count,
  published_at, updated_at, social_link_status
) VALUES (
  '00000000-0200-0000-0000-000000000012', '00000000-0210-0000-0000-000000000012', 'Fatt Kee Seafood Restaurant (Hilltop)', 'Lot 18, Ground Floor, Beverly Hills Plaza, Jalan Bundusan, 88300 Kota Kinabalu, Sabah', 'Sabah', 'Kota Kinabalu', 'Seafood / Noodles', '$$',
  'Fresh Fish Head Soup Noodles, Tom Yam Fish Paste Noodles, Fried Fish Fillet', 'https://www.instagram.com/fattkeeseafood', 'https://images.unsplash.com/photo-1534422298391-e4f8c172dddb', 'Fatt Kee Hilltop',
  'unclaimed', 5.9405, 116.0968, 4.6, 20,
  clock_timestamp() - interval '16 days', clock_timestamp() - interval '16 days', 'active'
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, address = EXCLUDED.address,
  state = EXCLUDED.state, city = EXCLUDED.city, cuisine_type = EXCLUDED.cuisine_type,
  price_range = EXCLUDED.price_range, reviewed_dishes = EXCLUDED.reviewed_dishes,
  social_media_url = EXCLUDED.social_media_url, cover_image_path = EXCLUDED.cover_image_path,
  latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count;


UPDATE public.restaurants SET current_revision_id = '00000000-0210-0000-0000-000000000013', approved_revision_id = '00000000-0210-0000-0000-000000000013' WHERE id = '00000000-0200-0000-0000-000000000013';

INSERT INTO public.published_restaurants (
  id, revision_id, name, address, state, city, cuisine_type, price_range,
  reviewed_dishes, social_media_url, cover_image_path, creator_display_name,
  ownership_status, latitude, longitude, rating_average, review_count,
  published_at, updated_at, social_link_status
) VALUES (
  '00000000-0200-0000-0000-000000000013', '00000000-0210-0000-0000-000000000013', 'Top Spot Food Court', 'Level 5, UTC Kuching, Jalan Bukit Mata Kuching, 93100 Kuching, Sarawak', 'Sarawak', 'Kuching', 'Seafood / Local', '$$',
  'Stir-fried Midin with Belacan, Butter Tiger Prawns, Crispy Oyster Pancake', 'https://www.instagram.com/topspotkuching', 'https://images.unsplash.com/photo-1559847844-5315695dadae', 'Top Spot Stalls',
  'unclaimed', 1.5562, 110.3541, 4.7, 36,
  clock_timestamp() - interval '15 days', clock_timestamp() - interval '15 days', 'active'
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, address = EXCLUDED.address,
  state = EXCLUDED.state, city = EXCLUDED.city, cuisine_type = EXCLUDED.cuisine_type,
  price_range = EXCLUDED.price_range, reviewed_dishes = EXCLUDED.reviewed_dishes,
  social_media_url = EXCLUDED.social_media_url, cover_image_path = EXCLUDED.cover_image_path,
  latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count;


UPDATE public.restaurants SET current_revision_id = '00000000-0210-0000-0000-000000000014', approved_revision_id = '00000000-0210-0000-0000-000000000014' WHERE id = '00000000-0200-0000-0000-000000000014';

INSERT INTO public.published_restaurants (
  id, revision_id, name, address, state, city, cuisine_type, price_range,
  reviewed_dishes, social_media_url, cover_image_path, creator_display_name,
  ownership_status, latitude, longitude, rating_average, review_count,
  published_at, updated_at, social_link_status
) VALUES (
  '00000000-0200-0000-0000-000000000014', '00000000-0210-0000-0000-000000000014', 'Choon Hui Cafe', '34, Jalan Ban Hock, 93100 Kuching, Sarawak', 'Sarawak', 'Kuching', 'Sarawak / Kopitiam', '$',
  'Sarawak Laksa (Anthony Bourdain recommended), Traditional Kolo Mee, Toast', 'https://www.instagram.com/choonhuicafe', 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624', 'Choon Hui Kopitiam',
  'unclaimed', 1.5517, 110.3546, 4.8, 33,
  clock_timestamp() - interval '14 days', clock_timestamp() - interval '14 days', 'active'
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, address = EXCLUDED.address,
  state = EXCLUDED.state, city = EXCLUDED.city, cuisine_type = EXCLUDED.cuisine_type,
  price_range = EXCLUDED.price_range, reviewed_dishes = EXCLUDED.reviewed_dishes,
  social_media_url = EXCLUDED.social_media_url, cover_image_path = EXCLUDED.cover_image_path,
  latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count;


UPDATE public.restaurants SET current_revision_id = '00000000-0210-0000-0000-000000000015', approved_revision_id = '00000000-0210-0000-0000-000000000015' WHERE id = '00000000-0200-0000-0000-000000000015';

INSERT INTO public.published_restaurants (
  id, revision_id, name, address, state, city, cuisine_type, price_range,
  reviewed_dishes, social_media_url, cover_image_path, creator_display_name,
  ownership_status, latitude, longitude, rating_average, review_count,
  published_at, updated_at, social_link_status
) VALUES (
  '00000000-0200-0000-0000-000000000015', '00000000-0210-0000-0000-000000000015', 'Restoran Kheng Pin', '80, Penang Road, 10000 George Town, Pulau Pinang', 'Pulau Pinang', 'George Town', 'Hainanese / Street Food', '$',
  'Hainanese Chicken Rice, Crispy Loh Bak, Prawn Fritters, Wan Tan Mee', 'https://www.instagram.com/khengpinpenang', 'https://images.unsplash.com/photo-1565299585323-38d6b0865b47', 'Kheng Pin Team',
  'unclaimed', 5.4194, 100.3326, 4.6, 22,
  clock_timestamp() - interval '13 days', clock_timestamp() - interval '13 days', 'active'
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, address = EXCLUDED.address,
  state = EXCLUDED.state, city = EXCLUDED.city, cuisine_type = EXCLUDED.cuisine_type,
  price_range = EXCLUDED.price_range, reviewed_dishes = EXCLUDED.reviewed_dishes,
  social_media_url = EXCLUDED.social_media_url, cover_image_path = EXCLUDED.cover_image_path,
  latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count;


UPDATE public.restaurants SET current_revision_id = '00000000-0210-0000-0000-000000000016', approved_revision_id = '00000000-0210-0000-0000-000000000016' WHERE id = '00000000-0200-0000-0000-000000000016';

INSERT INTO public.published_restaurants (
  id, revision_id, name, address, state, city, cuisine_type, price_range,
  reviewed_dishes, social_media_url, cover_image_path, creator_display_name,
  ownership_status, latitude, longitude, rating_average, review_count,
  published_at, updated_at, social_link_status
) VALUES (
  '00000000-0200-0000-0000-000000000016', '00000000-0210-0000-0000-000000000016', 'Capital Cafe', '213, Jalan Tuanku Abdul Rahman, City Centre, 50100 Kuala Lumpur', 'Kuala Lumpur', 'Kuala Lumpur', 'Kopitiam / Multi-ethnic', '$',
  'Mee Rebus, Rojak Mamak, Nasi Padang, Hainanese Hailam Coffee', 'https://www.instagram.com/capitalcafekl', 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb', 'Lin Family (Est 1956)',
  'unclaimed', 3.1554, 101.6967, 4.5, 19,
  clock_timestamp() - interval '12 days', clock_timestamp() - interval '12 days', 'active'
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, name = EXCLUDED.name, address = EXCLUDED.address,
  state = EXCLUDED.state, city = EXCLUDED.city, cuisine_type = EXCLUDED.cuisine_type,
  price_range = EXCLUDED.price_range, reviewed_dishes = EXCLUDED.reviewed_dishes,
  social_media_url = EXCLUDED.social_media_url, cover_image_path = EXCLUDED.cover_image_path,
  latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
  rating_average = EXCLUDED.rating_average, review_count = EXCLUDED.review_count;

UPDATE public.restaurants SET current_revision_id = '00000000-0210-0000-0000-000000000017', approved_revision_id = NULL WHERE id = '00000000-0200-0000-0000-000000000017';
UPDATE public.restaurants SET current_revision_id = '00000000-0210-0000-0000-000000000018', approved_revision_id = NULL WHERE id = '00000000-0200-0000-0000-000000000018';
UPDATE public.restaurants SET current_revision_id = '00000000-0210-0000-0000-000000000019', approved_revision_id = NULL WHERE id = '00000000-0200-0000-0000-000000000019';

-- 3.1 GUIDES (Base records)

INSERT INTO public.guides (id, creator_id, current_revision_id, published_revision_id, version, created_at)
VALUES ('00000000-0300-0000-0000-000000000001', NULL, NULL, NULL, 1, clock_timestamp() - interval '25 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.guides (id, creator_id, current_revision_id, published_revision_id, version, created_at)
VALUES ('00000000-0300-0000-0000-000000000002', NULL, NULL, NULL, 1, clock_timestamp() - interval '25 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.guides (id, creator_id, current_revision_id, published_revision_id, version, created_at)
VALUES ('00000000-0300-0000-0000-000000000003', NULL, NULL, NULL, 1, clock_timestamp() - interval '25 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.guides (id, creator_id, current_revision_id, published_revision_id, version, created_at)
VALUES ('00000000-0300-0000-0000-000000000004', NULL, NULL, NULL, 1, clock_timestamp() - interval '25 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.guides (id, creator_id, current_revision_id, published_revision_id, version, created_at)
VALUES ('00000000-0300-0000-0000-000000000005', NULL, NULL, NULL, 1, clock_timestamp() - interval '25 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.guides (id, creator_id, current_revision_id, published_revision_id, version, created_at)
VALUES ('00000000-0300-0000-0000-000000000006', NULL, NULL, NULL, 1, clock_timestamp() - interval '25 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.guides (id, creator_id, current_revision_id, published_revision_id, version, created_at)
VALUES ('00000000-0300-0000-0000-000000000007', NULL, NULL, NULL, 1, clock_timestamp() - interval '25 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.guides (id, creator_id, current_revision_id, published_revision_id, version, created_at)
VALUES ('00000000-0300-0000-0000-000000000008', NULL, NULL, NULL, 1, clock_timestamp() - interval '25 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.guides (id, creator_id, current_revision_id, published_revision_id, version, created_at)
VALUES ('00000000-0300-0000-0000-000000000009', NULL, NULL, NULL, 1, clock_timestamp() - interval '25 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.guides (id, creator_id, current_revision_id, published_revision_id, version, created_at)
VALUES ('00000000-0300-0000-0000-00000000000a', NULL, NULL, NULL, 1, clock_timestamp() - interval '25 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.guides (id, creator_id, current_revision_id, published_revision_id, version, created_at)
VALUES ('00000000-0300-0000-0000-00000000000b', NULL, NULL, NULL, 1, clock_timestamp() - interval '25 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.guides (id, creator_id, current_revision_id, published_revision_id, version, created_at)
VALUES ('00000000-0300-0000-0000-00000000000c', NULL, NULL, NULL, 1, clock_timestamp() - interval '25 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.guides (id, creator_id, current_revision_id, published_revision_id, version, created_at)
VALUES ('00000000-0300-0000-0000-00000000000d', NULL, NULL, NULL, 1, clock_timestamp() - interval '25 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.guides (id, creator_id, current_revision_id, published_revision_id, version, created_at)
VALUES ('00000000-0300-0000-0000-00000000000e', NULL, NULL, NULL, 1, clock_timestamp() - interval '25 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.guides (id, creator_id, current_revision_id, published_revision_id, version, created_at)
VALUES ('00000000-0300-0000-0000-00000000000f', NULL, NULL, NULL, 1, clock_timestamp() - interval '25 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.guides (id, creator_id, current_revision_id, published_revision_id, version, created_at)
VALUES ('00000000-0300-0000-0000-000000000010', NULL, NULL, NULL, 1, clock_timestamp() - interval '25 days')
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.guides (id, creator_id, current_revision_id, published_revision_id, version, created_at)
VALUES ('00000000-0300-0000-0000-000000000011', NULL, NULL, NULL, 1, clock_timestamp() - interval '25 days')
ON CONFLICT (id) DO NOTHING;


-- 3.2 GUIDE REVISIONS

INSERT INTO public.guide_revisions (
  id, guide_id, revision_number, author_id, status, title, location_name,
  state, route_overview, stops, walking_sequence, estimated_duration,
  submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0310-0000-0000-000000000001', '00000000-0300-0000-0000-000000000001', 1, NULL, 'approved', 'George Town UNESCO Heritage & Street Art Walk', 'George Town',
  'Pulau Pinang', 'A self-guided walking trail covering vibrant street art, historic clan houses, and iconic Peranakan mansions.', '["Cheong Fatt Tze Blue Mansion", "Pinang Peranakan Mansion", "Armenian Street Wall Art", "Khoo Kongsi Clan House"]'::jsonb, '["Start at Leith Street", "Walk east to Church Street", "Stroll south down Armenian Street", "End at Cannon Square"]'::jsonb, '3.5 hours',
  clock_timestamp() - interval '24 days', clock_timestamp() - interval '23 days',
  clock_timestamp() - interval '24 days', clock_timestamp() - interval '23 days'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, route_overview = EXCLUDED.route_overview, status = EXCLUDED.status;


INSERT INTO public.guide_revisions (
  id, guide_id, revision_number, author_id, status, title, location_name,
  state, route_overview, stops, walking_sequence, estimated_duration,
  submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0310-0000-0000-000000000002', '00000000-0300-0000-0000-000000000002', 1, NULL, 'approved', 'Kuala Lumpur Historic Colonial Core & River Trail', 'Merdeka Square',
  'Kuala Lumpur', 'Discover the founding roots of Kuala Lumpur at the confluence of the Klang and Gombak rivers.', '["Dataran Merdeka (Independence Square)", "Sultan Abdul Samad Building", "Masjid Jamek River of Life", "Central Market Pasar Seni"]'::jsonb, '["Begin at Merdeka Square flagpole", "Cross Sultan Abdul Samad heritage bridge", "View River of Life confluence", "Explore Central Market art stalls"]'::jsonb, '2.5 hours',
  clock_timestamp() - interval '23 days', clock_timestamp() - interval '22 days',
  clock_timestamp() - interval '23 days', clock_timestamp() - interval '22 days'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, route_overview = EXCLUDED.route_overview, status = EXCLUDED.status;


INSERT INTO public.guide_revisions (
  id, guide_id, revision_number, author_id, status, title, location_name,
  state, route_overview, stops, walking_sequence, estimated_duration,
  submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0310-0000-0000-000000000003', '00000000-0300-0000-0000-000000000003', 1, NULL, 'approved', 'Melaka Old Town Heritage & Riverside Walk', 'Old Town',
  'Melaka', 'Immerse in 500 years of multi-cultural colonial history spanning Portuguese, Dutch, and British eras.', '["The Stadthuys Red Square", "Christ Church Melaka", "St. Paul''s Hill Ruins", "A Famosa Porta de Santiago", "Jonker Street"]'::jsonb, '["Meet at Dutch Square fountain", "Admire red coral brick Christ Church", "Ascend St. Paul''s hill steps", "Descend to A Famosa fortress", "Cross bridge into Jonker Street"]'::jsonb, '3.0 hours',
  clock_timestamp() - interval '22 days', clock_timestamp() - interval '21 days',
  clock_timestamp() - interval '22 days', clock_timestamp() - interval '21 days'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, route_overview = EXCLUDED.route_overview, status = EXCLUDED.status;


INSERT INTO public.guide_revisions (
  id, guide_id, revision_number, author_id, status, title, location_name,
  state, route_overview, stops, walking_sequence, estimated_duration,
  submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0310-0000-0000-000000000004', '00000000-0300-0000-0000-000000000004', 1, NULL, 'approved', 'Ipoh Old Town Street Art & Kopitiam Trail', 'Old Town',
  'Perak', 'Follow vintage shophouses, Ernest Zacharevic murals, and legendary Hainanese coffee roasters.', '["Ipoh Railway Station (Taj Mahal of Ipoh)", "Concubine Lane", "Birch Memorial Clock Tower", "Sin Yoon Loong White Coffee"]'::jsonb, '["Start at colonial Railway Station", "Stroll down Panglima Lane", "Photograph mural walls around clock tower", "Enjoy afternoon white coffee and toast"]'::jsonb, '2.0 hours',
  clock_timestamp() - interval '21 days', clock_timestamp() - interval '20 days',
  clock_timestamp() - interval '21 days', clock_timestamp() - interval '20 days'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, route_overview = EXCLUDED.route_overview, status = EXCLUDED.status;


INSERT INTO public.guide_revisions (
  id, guide_id, revision_number, author_id, status, title, location_name,
  state, route_overview, stops, walking_sequence, estimated_duration,
  submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0310-0000-0000-000000000005', '00000000-0300-0000-0000-000000000005', 1, NULL, 'approved', 'Johor Bahru Old Town Cultural Trail', 'JB City Centre',
  'Johor', 'Experience the historic blend of Chinese pioneer roots, wood-fired bakeries, and royal architecture.', '["Tan Hiok Nee Heritage Walk", "Hiap Joo Wood-fired Bakery", "Johor Ancient Temple", "Sultan Abu Bakar State Mosque"]'::jsonb, '["Start at Tan Hiok Nee arch", "Queue for fresh banana cake at Hiap Joo", "Visit century-old Ancient Temple", "End at Royal Mosque hilltop"]'::jsonb, '2.5 hours',
  clock_timestamp() - interval '20 days', clock_timestamp() - interval '19 days',
  clock_timestamp() - interval '20 days', clock_timestamp() - interval '19 days'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, route_overview = EXCLUDED.route_overview, status = EXCLUDED.status;


INSERT INTO public.guide_revisions (
  id, guide_id, revision_number, author_id, status, title, location_name,
  state, route_overview, stops, walking_sequence, estimated_duration,
  submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0310-0000-0000-000000000006', '00000000-0300-0000-0000-000000000006', 1, NULL, 'approved', 'Chinatown KL Hidden Lanes & Food Heritage', 'Chinatown',
  'Kuala Lumpur', 'Navigate historic alleyways, secret cafe courtyards, and century-old culinary establishments.', '["Petaling Street Arch", "Sri Mahamariamman Hindu Temple", "Kwai Chai Hong Heritage Alley", "Kim Lian Kee Hokkien Mee"]'::jsonb, '["Pass Chinatown entrance arch", "Walk to High Street Hindu temple", "Capture lantern photos at Kwai Chai Hong", "Savor charcoal Hokkien noodles"]'::jsonb, '2.0 hours',
  clock_timestamp() - interval '19 days', clock_timestamp() - interval '18 days',
  clock_timestamp() - interval '19 days', clock_timestamp() - interval '18 days'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, route_overview = EXCLUDED.route_overview, status = EXCLUDED.status;


INSERT INTO public.guide_revisions (
  id, guide_id, revision_number, author_id, status, title, location_name,
  state, route_overview, stops, walking_sequence, estimated_duration,
  submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0310-0000-0000-000000000007', '00000000-0300-0000-0000-000000000007', 1, NULL, 'approved', 'Kuching Waterfront & Old Bazaar Heritage Walk', 'Waterfront',
  'Sarawak', 'Explore the romantic riverside of Kuching featuring Brooke-era monuments and vibrant street markets.', '["Kuching Waterfront Promenade", "Darul Hana S-Bridge", "Old Court House Cultural Hub", "Carpenter Street Food Lane"]'::jsonb, '["Begin at Main Bazaar waterfront", "Cross pedestrian Darul Hana Bridge", "Tour Old Court House pavilion", "Taste snacks on Carpenter Street"]'::jsonb, '2.0 hours',
  clock_timestamp() - interval '18 days', clock_timestamp() - interval '17 days',
  clock_timestamp() - interval '18 days', clock_timestamp() - interval '17 days'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, route_overview = EXCLUDED.route_overview, status = EXCLUDED.status;


INSERT INTO public.guide_revisions (
  id, guide_id, revision_number, author_id, status, title, location_name,
  state, route_overview, stops, walking_sequence, estimated_duration,
  submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0310-0000-0000-000000000008', '00000000-0300-0000-0000-000000000008', 1, NULL, 'approved', 'Kota Kinabalu Gaya Street & Coastal Sunset Trail', 'Gaya Street',
  'Sabah', 'An energetic walking route combining historical colonial monuments, famous laksa, and ocean sunsets.', '["Gaya Street Market & Yee Fung", "Atkinson Clock Tower", "Signal Hill Observatory Platform", "KK Waterfront Esplanade"]'::jsonb, '["Morning brunch at Yee Fung Laksa", "Walk up hill to Atkinson Clock Tower", "Take panorama photos at Signal Hill", "Sunset walk at Waterfront"]'::jsonb, '3.0 hours',
  clock_timestamp() - interval '17 days', clock_timestamp() - interval '16 days',
  clock_timestamp() - interval '17 days', clock_timestamp() - interval '16 days'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, route_overview = EXCLUDED.route_overview, status = EXCLUDED.status;


INSERT INTO public.guide_revisions (
  id, guide_id, revision_number, author_id, status, title, location_name,
  state, route_overview, stops, walking_sequence, estimated_duration,
  submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0310-0000-0000-000000000009', '00000000-0300-0000-0000-000000000009', 1, NULL, 'approved', 'Penang Hill to Kek Lok Si Nature & Temple Explorer', 'Air Itam',
  'Pulau Pinang', 'A full half-day tour linking Penang''s premier mountain resort with Southeast Asia''s grandest Buddhist temple.', '["Kek Lok Si Grand Pagoda", "Air Itam Market Trail", "Penang Hill Lower Station Funicular", "The Habitat Rainforest Canopy Walk"]'::jsonb, '["Morning exploration of Kek Lok Si pavilions", "Walk down to Air Itam for local refreshments", "Board Funicular to Hill summit", "Walk Curtis Crest canopy"]'::jsonb, '4.5 hours',
  clock_timestamp() - interval '16 days', clock_timestamp() - interval '15 days',
  clock_timestamp() - interval '16 days', clock_timestamp() - interval '15 days'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, route_overview = EXCLUDED.route_overview, status = EXCLUDED.status;


INSERT INTO public.guide_revisions (
  id, guide_id, revision_number, author_id, status, title, location_name,
  state, route_overview, stops, walking_sequence, estimated_duration,
  submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0310-0000-0000-00000000000a', '00000000-0300-0000-0000-00000000000a', 1, NULL, 'approved', 'Batu Caves & Selangor Cultural Excursion', 'Gombak',
  'Selangor', 'Explore spiritual karst caverns and traditional pewter artisanal craftsmanship.', '["Batu Caves 272 Rainbow Steps", "Ramayana Cave Mythological Dioramas", "Royal Selangor Pewter Visitor Centre"]'::jsonb, '["Climb Lord Murugan staircase into Temple Cave", "Explore illuminated Ramayana Cave", "Drive to Royal Selangor pewter foundry"]'::jsonb, '3.5 hours',
  clock_timestamp() - interval '15 days', clock_timestamp() - interval '14 days',
  clock_timestamp() - interval '15 days', clock_timestamp() - interval '14 days'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, route_overview = EXCLUDED.route_overview, status = EXCLUDED.status;


INSERT INTO public.guide_revisions (
  id, guide_id, revision_number, author_id, status, title, location_name,
  state, route_overview, stops, walking_sequence, estimated_duration,
  submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0310-0000-0000-00000000000b', '00000000-0300-0000-0000-00000000000b', 1, NULL, 'approved', 'Cameron Highlands Tea Valley & Cloud Forest Trail', 'Brinchang',
  'Pahang', 'A scenic highland route navigating rolling tea hills, cool cloud forests, and local agricultural markets.', '["Boh Tea Estate Sungai Palas", "Mossy Forest Elevated Boardwalk", "Kea Farm Vegetable & Strawberry Market"]'::jsonb, '["Early morning drive to Sungai Palas tea center", "Guided stroll along Mossy Forest boardwalk", "Shop Kea Farm fresh market"]'::jsonb, '4.0 hours',
  clock_timestamp() - interval '14 days', clock_timestamp() - interval '13 days',
  clock_timestamp() - interval '14 days', clock_timestamp() - interval '13 days'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, route_overview = EXCLUDED.route_overview, status = EXCLUDED.status;


INSERT INTO public.guide_revisions (
  id, guide_id, revision_number, author_id, status, title, location_name,
  state, route_overview, stops, walking_sequence, estimated_duration,
  submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0310-0000-0000-00000000000c', '00000000-0300-0000-0000-00000000000c', 1, NULL, 'approved', 'Desaru Coastal Scenic & Fruit Farm Gateway', 'Desaru',
  'Johor', 'A coastal road-trip trail celebrating tropical beaches, agricultural bounty, and fishermen heritage.', '["Desaru Public Beach", "Desaru Fruit Farm Tropical Agro-tour", "Tanjung Balau Fishermen Village & Museum"]'::jsonb, '["Morning stroll along Desaru golden sands", "Guided tropical fruit and honey tasting tour", "Visit coastal fishing village and maritime museum"]'::jsonb, '5.0 hours',
  clock_timestamp() - interval '13 days', clock_timestamp() - interval '12 days',
  clock_timestamp() - interval '13 days', clock_timestamp() - interval '12 days'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, route_overview = EXCLUDED.route_overview, status = EXCLUDED.status;


INSERT INTO public.guide_revisions (
  id, guide_id, revision_number, author_id, status, title, location_name,
  state, route_overview, stops, walking_sequence, estimated_duration,
  submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0310-0000-0000-00000000000d', '00000000-0300-0000-0000-00000000000d', 1, NULL, 'approved', 'Shah Alam Cultural & Mosque Architecture Trail', 'Seksyen 14',
  'Selangor', 'Appreciate grand Islamic architecture and tranquil lake parklands in Selangor''s royal capital.', '["Blue Mosque (Sultan Salahuddin Abdul Aziz)", "Shah Alam Lake Gardens", "Laman Seni 7 Street Art Murals"]'::jsonb, '["Join guided tour of Blue Mosque", "Stroll lakeside walking paths around West Lake", "Explore 3D street art installations at Seksyen 7"]'::jsonb, '2.5 hours',
  clock_timestamp() - interval '12 days', clock_timestamp() - interval '11 days',
  clock_timestamp() - interval '12 days', clock_timestamp() - interval '11 days'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, route_overview = EXCLUDED.route_overview, status = EXCLUDED.status;


INSERT INTO public.guide_revisions (
  id, guide_id, revision_number, author_id, status, title, location_name,
  state, route_overview, stops, walking_sequence, estimated_duration,
  submitted_at, decided_at, created_at, updated_at
) VALUES (
  '00000000-0310-0000-0000-00000000000e', '00000000-0300-0000-0000-00000000000e', 1, NULL, 'approved', 'Gopeng Heritage & Adventure Trail', 'Gopeng',
  'Perak', 'Trace tin-mining boomtown history before descending into prehistoric limestone labyrinth caves.', '["Gopeng Heritage Museum", "Gua Tempurung Show Caves", "Sungai Kampar Riverside Park"]'::jsonb, '["Tour mining heritage museum artifacts", "Explore subterranean cathedral chambers at Gua Tempurung", "Cool off by Sungai Kampar riverbank"]'::jsonb, '4.0 hours',
  clock_timestamp() - interval '11 days', clock_timestamp() - interval '10 days',
  clock_timestamp() - interval '11 days', clock_timestamp() - interval '10 days'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, route_overview = EXCLUDED.route_overview, status = EXCLUDED.status;


INSERT INTO public.guide_revisions (
  id, guide_id, revision_number, author_id, status, title, location_name,
  state, route_overview, stops, walking_sequence, estimated_duration,
  submitted_at, created_at, updated_at
) VALUES (
  '00000000-0310-0000-0000-00000000000f', '00000000-0300-0000-0000-00000000000f', 1, NULL, 'submitted', 'Langkawi Geopark & Mangrove Discovery Trail', 'Kilim Geoforest',
  'Kedah', 'Boat and boardwalk trail through ancient limestone karsts, eagle feeding grounds, and mangrove swamps.', '["Kilim Jetty", "Bat Cave (Gua Kelawar)", "Floating Fish Farm Restaurant", "Eagle Feeding Lagoon"]'::jsonb, '["Board eco-boat at Kilim Jetty", "Walk inside Bat Cave boardwalk", "Visit floating fish farm", "Cruise to majestic Brahminy Kite lagoon"]'::jsonb, '3.5 hours',
  clock_timestamp() - interval '1 day', clock_timestamp() - interval '1 day', clock_timestamp() - interval '1 day'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, route_overview = EXCLUDED.route_overview, status = EXCLUDED.status;


INSERT INTO public.guide_revisions (
  id, guide_id, revision_number, author_id, status, title, location_name,
  state, route_overview, stops, walking_sequence, estimated_duration,
  submitted_at, created_at, updated_at
) VALUES (
  '00000000-0310-0000-0000-000000000010', '00000000-0300-0000-0000-000000000010', 1, NULL, 'submitted', 'Kuala Selangor Fireflies & Coastal Nature Walk', 'Bukit Melawati',
  'Selangor', 'Historic coastal hill exploration followed by evening mangrove boat cruise to see synchronized fireflies.', '["Bukit Melawati Lighthouse & Fort", "Kuala Selangor Nature Park Mangroves", "Kampung Kuantan Firefly Sanctuary"]'::jsonb, '["Visit hilltop colonial lighthouse and spot monkeys", "Evening mangrove boardwalk trail", "Silent sampan ride under firefly trees"]'::jsonb, '4.0 hours',
  clock_timestamp() - interval '1 day', clock_timestamp() - interval '1 day', clock_timestamp() - interval '1 day'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, route_overview = EXCLUDED.route_overview, status = EXCLUDED.status;


INSERT INTO public.guide_revisions (
  id, guide_id, revision_number, author_id, status, title, location_name,
  state, route_overview, stops, walking_sequence, estimated_duration,
  submitted_at, created_at, updated_at
) VALUES (
  '00000000-0310-0000-0000-000000000011', '00000000-0300-0000-0000-000000000011', 1, NULL, 'submitted', 'Sandakan Heritage & Wildlife Trail', 'Sandakan',
  'Sabah', 'Historical memorial walk followed by wildlife encounters at Sepilok forest reserve.', '["Sandakan Memorial Park", "Pu Ji Shih Buddhist Temple", "Sepilok Orangutan Centre"]'::jsonb, '["Pay respects at peaceful Memorial Park", "View Sandakan Bay from hilltop Pu Ji Shih temple", "Attend 3:00 PM Sepilok orangutan feeding"]'::jsonb, '4.5 hours',
  clock_timestamp() - interval '1 day', clock_timestamp() - interval '1 day', clock_timestamp() - interval '1 day'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, route_overview = EXCLUDED.route_overview, status = EXCLUDED.status;


-- 3.3 PUBLISHED GUIDES & GUIDES POINTER UPDATES

UPDATE public.guides SET current_revision_id = '00000000-0310-0000-0000-000000000001', published_revision_id = '00000000-0310-0000-0000-000000000001' WHERE id = '00000000-0300-0000-0000-000000000001';

INSERT INTO public.published_guides (
  id, revision_id, title, location_name, state, route_overview,
  stops, walking_sequence, estimated_duration, published_at, updated_at, guide_version
) VALUES (
  '00000000-0300-0000-0000-000000000001', '00000000-0310-0000-0000-000000000001', 'George Town UNESCO Heritage & Street Art Walk', 'George Town', 'Pulau Pinang', 'A self-guided walking trail covering vibrant street art, historic clan houses, and iconic Peranakan mansions.',
  '["Cheong Fatt Tze Blue Mansion", "Pinang Peranakan Mansion", "Armenian Street Wall Art", "Khoo Kongsi Clan House"]'::jsonb, '["Start at Leith Street", "Walk east to Church Street", "Stroll south down Armenian Street", "End at Cannon Square"]'::jsonb, '3.5 hours',
  clock_timestamp() - interval '23 days', clock_timestamp() - interval '23 days', 1
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, title = EXCLUDED.title, location_name = EXCLUDED.location_name,
  state = EXCLUDED.state, route_overview = EXCLUDED.route_overview, stops = EXCLUDED.stops,
  walking_sequence = EXCLUDED.walking_sequence, estimated_duration = EXCLUDED.estimated_duration;


UPDATE public.guides SET current_revision_id = '00000000-0310-0000-0000-000000000002', published_revision_id = '00000000-0310-0000-0000-000000000002' WHERE id = '00000000-0300-0000-0000-000000000002';

INSERT INTO public.published_guides (
  id, revision_id, title, location_name, state, route_overview,
  stops, walking_sequence, estimated_duration, published_at, updated_at, guide_version
) VALUES (
  '00000000-0300-0000-0000-000000000002', '00000000-0310-0000-0000-000000000002', 'Kuala Lumpur Historic Colonial Core & River Trail', 'Merdeka Square', 'Kuala Lumpur', 'Discover the founding roots of Kuala Lumpur at the confluence of the Klang and Gombak rivers.',
  '["Dataran Merdeka (Independence Square)", "Sultan Abdul Samad Building", "Masjid Jamek River of Life", "Central Market Pasar Seni"]'::jsonb, '["Begin at Merdeka Square flagpole", "Cross Sultan Abdul Samad heritage bridge", "View River of Life confluence", "Explore Central Market art stalls"]'::jsonb, '2.5 hours',
  clock_timestamp() - interval '22 days', clock_timestamp() - interval '22 days', 1
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, title = EXCLUDED.title, location_name = EXCLUDED.location_name,
  state = EXCLUDED.state, route_overview = EXCLUDED.route_overview, stops = EXCLUDED.stops,
  walking_sequence = EXCLUDED.walking_sequence, estimated_duration = EXCLUDED.estimated_duration;


UPDATE public.guides SET current_revision_id = '00000000-0310-0000-0000-000000000003', published_revision_id = '00000000-0310-0000-0000-000000000003' WHERE id = '00000000-0300-0000-0000-000000000003';

INSERT INTO public.published_guides (
  id, revision_id, title, location_name, state, route_overview,
  stops, walking_sequence, estimated_duration, published_at, updated_at, guide_version
) VALUES (
  '00000000-0300-0000-0000-000000000003', '00000000-0310-0000-0000-000000000003', 'Melaka Old Town Heritage & Riverside Walk', 'Old Town', 'Melaka', 'Immerse in 500 years of multi-cultural colonial history spanning Portuguese, Dutch, and British eras.',
  '["The Stadthuys Red Square", "Christ Church Melaka", "St. Paul''s Hill Ruins", "A Famosa Porta de Santiago", "Jonker Street"]'::jsonb, '["Meet at Dutch Square fountain", "Admire red coral brick Christ Church", "Ascend St. Paul''s hill steps", "Descend to A Famosa fortress", "Cross bridge into Jonker Street"]'::jsonb, '3.0 hours',
  clock_timestamp() - interval '21 days', clock_timestamp() - interval '21 days', 1
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, title = EXCLUDED.title, location_name = EXCLUDED.location_name,
  state = EXCLUDED.state, route_overview = EXCLUDED.route_overview, stops = EXCLUDED.stops,
  walking_sequence = EXCLUDED.walking_sequence, estimated_duration = EXCLUDED.estimated_duration;


UPDATE public.guides SET current_revision_id = '00000000-0310-0000-0000-000000000004', published_revision_id = '00000000-0310-0000-0000-000000000004' WHERE id = '00000000-0300-0000-0000-000000000004';

INSERT INTO public.published_guides (
  id, revision_id, title, location_name, state, route_overview,
  stops, walking_sequence, estimated_duration, published_at, updated_at, guide_version
) VALUES (
  '00000000-0300-0000-0000-000000000004', '00000000-0310-0000-0000-000000000004', 'Ipoh Old Town Street Art & Kopitiam Trail', 'Old Town', 'Perak', 'Follow vintage shophouses, Ernest Zacharevic murals, and legendary Hainanese coffee roasters.',
  '["Ipoh Railway Station (Taj Mahal of Ipoh)", "Concubine Lane", "Birch Memorial Clock Tower", "Sin Yoon Loong White Coffee"]'::jsonb, '["Start at colonial Railway Station", "Stroll down Panglima Lane", "Photograph mural walls around clock tower", "Enjoy afternoon white coffee and toast"]'::jsonb, '2.0 hours',
  clock_timestamp() - interval '20 days', clock_timestamp() - interval '20 days', 1
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, title = EXCLUDED.title, location_name = EXCLUDED.location_name,
  state = EXCLUDED.state, route_overview = EXCLUDED.route_overview, stops = EXCLUDED.stops,
  walking_sequence = EXCLUDED.walking_sequence, estimated_duration = EXCLUDED.estimated_duration;


UPDATE public.guides SET current_revision_id = '00000000-0310-0000-0000-000000000005', published_revision_id = '00000000-0310-0000-0000-000000000005' WHERE id = '00000000-0300-0000-0000-000000000005';

INSERT INTO public.published_guides (
  id, revision_id, title, location_name, state, route_overview,
  stops, walking_sequence, estimated_duration, published_at, updated_at, guide_version
) VALUES (
  '00000000-0300-0000-0000-000000000005', '00000000-0310-0000-0000-000000000005', 'Johor Bahru Old Town Cultural Trail', 'JB City Centre', 'Johor', 'Experience the historic blend of Chinese pioneer roots, wood-fired bakeries, and royal architecture.',
  '["Tan Hiok Nee Heritage Walk", "Hiap Joo Wood-fired Bakery", "Johor Ancient Temple", "Sultan Abu Bakar State Mosque"]'::jsonb, '["Start at Tan Hiok Nee arch", "Queue for fresh banana cake at Hiap Joo", "Visit century-old Ancient Temple", "End at Royal Mosque hilltop"]'::jsonb, '2.5 hours',
  clock_timestamp() - interval '19 days', clock_timestamp() - interval '19 days', 1
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, title = EXCLUDED.title, location_name = EXCLUDED.location_name,
  state = EXCLUDED.state, route_overview = EXCLUDED.route_overview, stops = EXCLUDED.stops,
  walking_sequence = EXCLUDED.walking_sequence, estimated_duration = EXCLUDED.estimated_duration;


UPDATE public.guides SET current_revision_id = '00000000-0310-0000-0000-000000000006', published_revision_id = '00000000-0310-0000-0000-000000000006' WHERE id = '00000000-0300-0000-0000-000000000006';

INSERT INTO public.published_guides (
  id, revision_id, title, location_name, state, route_overview,
  stops, walking_sequence, estimated_duration, published_at, updated_at, guide_version
) VALUES (
  '00000000-0300-0000-0000-000000000006', '00000000-0310-0000-0000-000000000006', 'Chinatown KL Hidden Lanes & Food Heritage', 'Chinatown', 'Kuala Lumpur', 'Navigate historic alleyways, secret cafe courtyards, and century-old culinary establishments.',
  '["Petaling Street Arch", "Sri Mahamariamman Hindu Temple", "Kwai Chai Hong Heritage Alley", "Kim Lian Kee Hokkien Mee"]'::jsonb, '["Pass Chinatown entrance arch", "Walk to High Street Hindu temple", "Capture lantern photos at Kwai Chai Hong", "Savor charcoal Hokkien noodles"]'::jsonb, '2.0 hours',
  clock_timestamp() - interval '18 days', clock_timestamp() - interval '18 days', 1
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, title = EXCLUDED.title, location_name = EXCLUDED.location_name,
  state = EXCLUDED.state, route_overview = EXCLUDED.route_overview, stops = EXCLUDED.stops,
  walking_sequence = EXCLUDED.walking_sequence, estimated_duration = EXCLUDED.estimated_duration;


UPDATE public.guides SET current_revision_id = '00000000-0310-0000-0000-000000000007', published_revision_id = '00000000-0310-0000-0000-000000000007' WHERE id = '00000000-0300-0000-0000-000000000007';

INSERT INTO public.published_guides (
  id, revision_id, title, location_name, state, route_overview,
  stops, walking_sequence, estimated_duration, published_at, updated_at, guide_version
) VALUES (
  '00000000-0300-0000-0000-000000000007', '00000000-0310-0000-0000-000000000007', 'Kuching Waterfront & Old Bazaar Heritage Walk', 'Waterfront', 'Sarawak', 'Explore the romantic riverside of Kuching featuring Brooke-era monuments and vibrant street markets.',
  '["Kuching Waterfront Promenade", "Darul Hana S-Bridge", "Old Court House Cultural Hub", "Carpenter Street Food Lane"]'::jsonb, '["Begin at Main Bazaar waterfront", "Cross pedestrian Darul Hana Bridge", "Tour Old Court House pavilion", "Taste snacks on Carpenter Street"]'::jsonb, '2.0 hours',
  clock_timestamp() - interval '17 days', clock_timestamp() - interval '17 days', 1
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, title = EXCLUDED.title, location_name = EXCLUDED.location_name,
  state = EXCLUDED.state, route_overview = EXCLUDED.route_overview, stops = EXCLUDED.stops,
  walking_sequence = EXCLUDED.walking_sequence, estimated_duration = EXCLUDED.estimated_duration;


UPDATE public.guides SET current_revision_id = '00000000-0310-0000-0000-000000000008', published_revision_id = '00000000-0310-0000-0000-000000000008' WHERE id = '00000000-0300-0000-0000-000000000008';

INSERT INTO public.published_guides (
  id, revision_id, title, location_name, state, route_overview,
  stops, walking_sequence, estimated_duration, published_at, updated_at, guide_version
) VALUES (
  '00000000-0300-0000-0000-000000000008', '00000000-0310-0000-0000-000000000008', 'Kota Kinabalu Gaya Street & Coastal Sunset Trail', 'Gaya Street', 'Sabah', 'An energetic walking route combining historical colonial monuments, famous laksa, and ocean sunsets.',
  '["Gaya Street Market & Yee Fung", "Atkinson Clock Tower", "Signal Hill Observatory Platform", "KK Waterfront Esplanade"]'::jsonb, '["Morning brunch at Yee Fung Laksa", "Walk up hill to Atkinson Clock Tower", "Take panorama photos at Signal Hill", "Sunset walk at Waterfront"]'::jsonb, '3.0 hours',
  clock_timestamp() - interval '16 days', clock_timestamp() - interval '16 days', 1
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, title = EXCLUDED.title, location_name = EXCLUDED.location_name,
  state = EXCLUDED.state, route_overview = EXCLUDED.route_overview, stops = EXCLUDED.stops,
  walking_sequence = EXCLUDED.walking_sequence, estimated_duration = EXCLUDED.estimated_duration;


UPDATE public.guides SET current_revision_id = '00000000-0310-0000-0000-000000000009', published_revision_id = '00000000-0310-0000-0000-000000000009' WHERE id = '00000000-0300-0000-0000-000000000009';

INSERT INTO public.published_guides (
  id, revision_id, title, location_name, state, route_overview,
  stops, walking_sequence, estimated_duration, published_at, updated_at, guide_version
) VALUES (
  '00000000-0300-0000-0000-000000000009', '00000000-0310-0000-0000-000000000009', 'Penang Hill to Kek Lok Si Nature & Temple Explorer', 'Air Itam', 'Pulau Pinang', 'A full half-day tour linking Penang''s premier mountain resort with Southeast Asia''s grandest Buddhist temple.',
  '["Kek Lok Si Grand Pagoda", "Air Itam Market Trail", "Penang Hill Lower Station Funicular", "The Habitat Rainforest Canopy Walk"]'::jsonb, '["Morning exploration of Kek Lok Si pavilions", "Walk down to Air Itam for local refreshments", "Board Funicular to Hill summit", "Walk Curtis Crest canopy"]'::jsonb, '4.5 hours',
  clock_timestamp() - interval '15 days', clock_timestamp() - interval '15 days', 1
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, title = EXCLUDED.title, location_name = EXCLUDED.location_name,
  state = EXCLUDED.state, route_overview = EXCLUDED.route_overview, stops = EXCLUDED.stops,
  walking_sequence = EXCLUDED.walking_sequence, estimated_duration = EXCLUDED.estimated_duration;


UPDATE public.guides SET current_revision_id = '00000000-0310-0000-0000-00000000000a', published_revision_id = '00000000-0310-0000-0000-00000000000a' WHERE id = '00000000-0300-0000-0000-00000000000a';

INSERT INTO public.published_guides (
  id, revision_id, title, location_name, state, route_overview,
  stops, walking_sequence, estimated_duration, published_at, updated_at, guide_version
) VALUES (
  '00000000-0300-0000-0000-00000000000a', '00000000-0310-0000-0000-00000000000a', 'Batu Caves & Selangor Cultural Excursion', 'Gombak', 'Selangor', 'Explore spiritual karst caverns and traditional pewter artisanal craftsmanship.',
  '["Batu Caves 272 Rainbow Steps", "Ramayana Cave Mythological Dioramas", "Royal Selangor Pewter Visitor Centre"]'::jsonb, '["Climb Lord Murugan staircase into Temple Cave", "Explore illuminated Ramayana Cave", "Drive to Royal Selangor pewter foundry"]'::jsonb, '3.5 hours',
  clock_timestamp() - interval '14 days', clock_timestamp() - interval '14 days', 1
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, title = EXCLUDED.title, location_name = EXCLUDED.location_name,
  state = EXCLUDED.state, route_overview = EXCLUDED.route_overview, stops = EXCLUDED.stops,
  walking_sequence = EXCLUDED.walking_sequence, estimated_duration = EXCLUDED.estimated_duration;


UPDATE public.guides SET current_revision_id = '00000000-0310-0000-0000-00000000000b', published_revision_id = '00000000-0310-0000-0000-00000000000b' WHERE id = '00000000-0300-0000-0000-00000000000b';

INSERT INTO public.published_guides (
  id, revision_id, title, location_name, state, route_overview,
  stops, walking_sequence, estimated_duration, published_at, updated_at, guide_version
) VALUES (
  '00000000-0300-0000-0000-00000000000b', '00000000-0310-0000-0000-00000000000b', 'Cameron Highlands Tea Valley & Cloud Forest Trail', 'Brinchang', 'Pahang', 'A scenic highland route navigating rolling tea hills, cool cloud forests, and local agricultural markets.',
  '["Boh Tea Estate Sungai Palas", "Mossy Forest Elevated Boardwalk", "Kea Farm Vegetable & Strawberry Market"]'::jsonb, '["Early morning drive to Sungai Palas tea center", "Guided stroll along Mossy Forest boardwalk", "Shop Kea Farm fresh market"]'::jsonb, '4.0 hours',
  clock_timestamp() - interval '13 days', clock_timestamp() - interval '13 days', 1
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, title = EXCLUDED.title, location_name = EXCLUDED.location_name,
  state = EXCLUDED.state, route_overview = EXCLUDED.route_overview, stops = EXCLUDED.stops,
  walking_sequence = EXCLUDED.walking_sequence, estimated_duration = EXCLUDED.estimated_duration;


UPDATE public.guides SET current_revision_id = '00000000-0310-0000-0000-00000000000c', published_revision_id = '00000000-0310-0000-0000-00000000000c' WHERE id = '00000000-0300-0000-0000-00000000000c';

INSERT INTO public.published_guides (
  id, revision_id, title, location_name, state, route_overview,
  stops, walking_sequence, estimated_duration, published_at, updated_at, guide_version
) VALUES (
  '00000000-0300-0000-0000-00000000000c', '00000000-0310-0000-0000-00000000000c', 'Desaru Coastal Scenic & Fruit Farm Gateway', 'Desaru', 'Johor', 'A coastal road-trip trail celebrating tropical beaches, agricultural bounty, and fishermen heritage.',
  '["Desaru Public Beach", "Desaru Fruit Farm Tropical Agro-tour", "Tanjung Balau Fishermen Village & Museum"]'::jsonb, '["Morning stroll along Desaru golden sands", "Guided tropical fruit and honey tasting tour", "Visit coastal fishing village and maritime museum"]'::jsonb, '5.0 hours',
  clock_timestamp() - interval '12 days', clock_timestamp() - interval '12 days', 1
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, title = EXCLUDED.title, location_name = EXCLUDED.location_name,
  state = EXCLUDED.state, route_overview = EXCLUDED.route_overview, stops = EXCLUDED.stops,
  walking_sequence = EXCLUDED.walking_sequence, estimated_duration = EXCLUDED.estimated_duration;


UPDATE public.guides SET current_revision_id = '00000000-0310-0000-0000-00000000000d', published_revision_id = '00000000-0310-0000-0000-00000000000d' WHERE id = '00000000-0300-0000-0000-00000000000d';

INSERT INTO public.published_guides (
  id, revision_id, title, location_name, state, route_overview,
  stops, walking_sequence, estimated_duration, published_at, updated_at, guide_version
) VALUES (
  '00000000-0300-0000-0000-00000000000d', '00000000-0310-0000-0000-00000000000d', 'Shah Alam Cultural & Mosque Architecture Trail', 'Seksyen 14', 'Selangor', 'Appreciate grand Islamic architecture and tranquil lake parklands in Selangor''s royal capital.',
  '["Blue Mosque (Sultan Salahuddin Abdul Aziz)", "Shah Alam Lake Gardens", "Laman Seni 7 Street Art Murals"]'::jsonb, '["Join guided tour of Blue Mosque", "Stroll lakeside walking paths around West Lake", "Explore 3D street art installations at Seksyen 7"]'::jsonb, '2.5 hours',
  clock_timestamp() - interval '11 days', clock_timestamp() - interval '11 days', 1
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, title = EXCLUDED.title, location_name = EXCLUDED.location_name,
  state = EXCLUDED.state, route_overview = EXCLUDED.route_overview, stops = EXCLUDED.stops,
  walking_sequence = EXCLUDED.walking_sequence, estimated_duration = EXCLUDED.estimated_duration;


UPDATE public.guides SET current_revision_id = '00000000-0310-0000-0000-00000000000e', published_revision_id = '00000000-0310-0000-0000-00000000000e' WHERE id = '00000000-0300-0000-0000-00000000000e';

INSERT INTO public.published_guides (
  id, revision_id, title, location_name, state, route_overview,
  stops, walking_sequence, estimated_duration, published_at, updated_at, guide_version
) VALUES (
  '00000000-0300-0000-0000-00000000000e', '00000000-0310-0000-0000-00000000000e', 'Gopeng Heritage & Adventure Trail', 'Gopeng', 'Perak', 'Trace tin-mining boomtown history before descending into prehistoric limestone labyrinth caves.',
  '["Gopeng Heritage Museum", "Gua Tempurung Show Caves", "Sungai Kampar Riverside Park"]'::jsonb, '["Tour mining heritage museum artifacts", "Explore subterranean cathedral chambers at Gua Tempurung", "Cool off by Sungai Kampar riverbank"]'::jsonb, '4.0 hours',
  clock_timestamp() - interval '10 days', clock_timestamp() - interval '10 days', 1
) ON CONFLICT (id) DO UPDATE SET
  revision_id = EXCLUDED.revision_id, title = EXCLUDED.title, location_name = EXCLUDED.location_name,
  state = EXCLUDED.state, route_overview = EXCLUDED.route_overview, stops = EXCLUDED.stops,
  walking_sequence = EXCLUDED.walking_sequence, estimated_duration = EXCLUDED.estimated_duration;

UPDATE public.guides SET current_revision_id = '00000000-0310-0000-0000-00000000000f', published_revision_id = NULL WHERE id = '00000000-0300-0000-0000-00000000000f';
UPDATE public.guides SET current_revision_id = '00000000-0310-0000-0000-000000000010', published_revision_id = NULL WHERE id = '00000000-0300-0000-0000-000000000010';
UPDATE public.guides SET current_revision_id = '00000000-0310-0000-0000-000000000011', published_revision_id = NULL WHERE id = '00000000-0300-0000-0000-000000000011';

-- 4. SYNTHETIC PUBLIC REVIEWS (46 Reviews across Spots and Restaurants)

INSERT INTO public.reviews (id, user_id, target_type, target_id, rating, body, author_display_name, status, version, created_at, updated_at)
VALUES ('00000000-0400-0000-0000-000000000001', NULL, 'spot', '00000000-0100-0000-0000-000000000001', 5, 'Incredible cultural experience! The architecture and peaceful atmosphere made our morning visit truly unforgettable.', 'Demo Reviewer 01', 'published', 1, clock_timestamp() - interval '29 days', clock_timestamp() - interval '29 days')
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating;

INSERT INTO public.public_reviews (id, target_type, target_id, rating, body, author_display_name, version, created_at, updated_at, likes_count, dislikes_count)
VALUES ('00000000-0400-0000-0000-000000000001', 'spot', '00000000-0100-0000-0000-000000000001', 5, 'Incredible cultural experience! The architecture and peaceful atmosphere made our morning visit truly unforgettable.', 'Demo Reviewer 01', 1, clock_timestamp() - interval '29 days', clock_timestamp() - interval '29 days', 1, 0)
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating, likes_count = EXCLUDED.likes_count;


INSERT INTO public.reviews (id, user_id, target_type, target_id, rating, body, author_display_name, status, version, created_at, updated_at)
VALUES ('00000000-0400-0000-0000-000000000002', NULL, 'spot', '00000000-0100-0000-0000-000000000002', 5, 'A must-visit Malaysian attraction. Stunning views, rich heritage, and very accessible. Arrive early to beat the crowd.', 'Demo Reviewer 02', 'published', 1, clock_timestamp() - interval '28 days', clock_timestamp() - interval '28 days')
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating;

INSERT INTO public.public_reviews (id, target_type, target_id, rating, body, author_display_name, version, created_at, updated_at, likes_count, dislikes_count)
VALUES ('00000000-0400-0000-0000-000000000002', 'spot', '00000000-0100-0000-0000-000000000002', 5, 'A must-visit Malaysian attraction. Stunning views, rich heritage, and very accessible. Arrive early to beat the crowd.', 'Demo Reviewer 02', 1, clock_timestamp() - interval '28 days', clock_timestamp() - interval '28 days', 2, 0)
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating, likes_count = EXCLUDED.likes_count;


INSERT INTO public.reviews (id, user_id, target_type, target_id, rating, body, author_display_name, status, version, created_at, updated_at)
VALUES ('00000000-0400-0000-0000-000000000003', NULL, 'spot', '00000000-0100-0000-0000-000000000003', 4, 'Great place for photography and family walks. The surrounding area has plenty of local refreshment options.', 'Demo Reviewer 03', 'published', 1, clock_timestamp() - interval '27 days', clock_timestamp() - interval '27 days')
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating;

INSERT INTO public.public_reviews (id, target_type, target_id, rating, body, author_display_name, version, created_at, updated_at, likes_count, dislikes_count)
VALUES ('00000000-0400-0000-0000-000000000003', 'spot', '00000000-0100-0000-0000-000000000003', 4, 'Great place for photography and family walks. The surrounding area has plenty of local refreshment options.', 'Demo Reviewer 03', 1, clock_timestamp() - interval '27 days', clock_timestamp() - interval '27 days', 3, 0)
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating, likes_count = EXCLUDED.likes_count;


INSERT INTO public.reviews (id, user_id, target_type, target_id, rating, body, author_display_name, status, version, created_at, updated_at)
VALUES ('00000000-0400-0000-0000-000000000004', NULL, 'spot', '00000000-0100-0000-0000-000000000004', 4, 'Fascinating historical significance and well-maintained pathways. Highly recommended for weekend explorers.', 'Demo Reviewer 04', 'published', 1, clock_timestamp() - interval '26 days', clock_timestamp() - interval '26 days')
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating;

INSERT INTO public.public_reviews (id, target_type, target_id, rating, body, author_display_name, version, created_at, updated_at, likes_count, dislikes_count)
VALUES ('00000000-0400-0000-0000-000000000004', 'spot', '00000000-0100-0000-0000-000000000004', 4, 'Fascinating historical significance and well-maintained pathways. Highly recommended for weekend explorers.', 'Demo Reviewer 04', 1, clock_timestamp() - interval '26 days', clock_timestamp() - interval '26 days', 4, 0)
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating, likes_count = EXCLUDED.likes_count;


INSERT INTO public.reviews (id, user_id, target_type, target_id, rating, body, author_display_name, status, version, created_at, updated_at)
VALUES ('00000000-0400-0000-0000-000000000005', NULL, 'spot', '00000000-0100-0000-0000-000000000005', 5, 'Incredible cultural experience! The architecture and peaceful atmosphere made our morning visit truly unforgettable.', 'Demo Tourist', 'published', 1, clock_timestamp() - interval '25 days', clock_timestamp() - interval '25 days')
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating;

INSERT INTO public.public_reviews (id, target_type, target_id, rating, body, author_display_name, version, created_at, updated_at, likes_count, dislikes_count)
VALUES ('00000000-0400-0000-0000-000000000005', 'spot', '00000000-0100-0000-0000-000000000005', 5, 'Incredible cultural experience! The architecture and peaceful atmosphere made our morning visit truly unforgettable.', 'Demo Tourist', 1, clock_timestamp() - interval '25 days', clock_timestamp() - interval '25 days', 5, 0)
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating, likes_count = EXCLUDED.likes_count;


INSERT INTO public.reviews (id, user_id, target_type, target_id, rating, body, author_display_name, status, version, created_at, updated_at)
VALUES ('00000000-0400-0000-0000-000000000006', NULL, 'spot', '00000000-0100-0000-0000-000000000006', 5, 'A must-visit Malaysian attraction. Stunning views, rich heritage, and very accessible. Arrive early to beat the crowd.', 'Demo Foodie', 'published', 1, clock_timestamp() - interval '24 days', clock_timestamp() - interval '24 days')
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating;

INSERT INTO public.public_reviews (id, target_type, target_id, rating, body, author_display_name, version, created_at, updated_at, likes_count, dislikes_count)
VALUES ('00000000-0400-0000-0000-000000000006', 'spot', '00000000-0100-0000-0000-000000000006', 5, 'A must-visit Malaysian attraction. Stunning views, rich heritage, and very accessible. Arrive early to beat the crowd.', 'Demo Foodie', 1, clock_timestamp() - interval '24 days', clock_timestamp() - interval '24 days', 6, 0)
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating, likes_count = EXCLUDED.likes_count;


INSERT INTO public.reviews (id, user_id, target_type, target_id, rating, body, author_display_name, status, version, created_at, updated_at)
VALUES ('00000000-0400-0000-0000-000000000007', NULL, 'spot', '00000000-0100-0000-0000-000000000007', 4, 'Great place for photography and family walks. The surrounding area has plenty of local refreshment options.', 'Demo Reviewer 01', 'published', 1, clock_timestamp() - interval '23 days', clock_timestamp() - interval '23 days')
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating;

INSERT INTO public.public_reviews (id, target_type, target_id, rating, body, author_display_name, version, created_at, updated_at, likes_count, dislikes_count)
VALUES ('00000000-0400-0000-0000-000000000007', 'spot', '00000000-0100-0000-0000-000000000007', 4, 'Great place for photography and family walks. The surrounding area has plenty of local refreshment options.', 'Demo Reviewer 01', 1, clock_timestamp() - interval '23 days', clock_timestamp() - interval '23 days', 7, 0)
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating, likes_count = EXCLUDED.likes_count;


INSERT INTO public.reviews (id, user_id, target_type, target_id, rating, body, author_display_name, status, version, created_at, updated_at)
VALUES ('00000000-0400-0000-0000-000000000008', NULL, 'spot', '00000000-0100-0000-0000-000000000008', 4, 'Fascinating historical significance and well-maintained pathways. Highly recommended for weekend explorers.', 'Demo Reviewer 02', 'published', 1, clock_timestamp() - interval '22 days', clock_timestamp() - interval '22 days')
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating;

INSERT INTO public.public_reviews (id, target_type, target_id, rating, body, author_display_name, version, created_at, updated_at, likes_count, dislikes_count)
VALUES ('00000000-0400-0000-0000-000000000008', 'spot', '00000000-0100-0000-0000-000000000008', 4, 'Fascinating historical significance and well-maintained pathways. Highly recommended for weekend explorers.', 'Demo Reviewer 02', 1, clock_timestamp() - interval '22 days', clock_timestamp() - interval '22 days', 0, 0)
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating, likes_count = EXCLUDED.likes_count;


INSERT INTO public.reviews (id, user_id, target_type, target_id, rating, body, author_display_name, status, version, created_at, updated_at)
VALUES ('00000000-0400-0000-0000-000000000009', NULL, 'spot', '00000000-0100-0000-0000-000000000009', 5, 'Incredible cultural experience! The architecture and peaceful atmosphere made our morning visit truly unforgettable.', 'Demo Reviewer 03', 'published', 1, clock_timestamp() - interval '21 days', clock_timestamp() - interval '21 days')
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating;

INSERT INTO public.public_reviews (id, target_type, target_id, rating, body, author_display_name, version, created_at, updated_at, likes_count, dislikes_count)
VALUES ('00000000-0400-0000-0000-000000000009', 'spot', '00000000-0100-0000-0000-000000000009', 5, 'Incredible cultural experience! The architecture and peaceful atmosphere made our morning visit truly unforgettable.', 'Demo Reviewer 03', 1, clock_timestamp() - interval '21 days', clock_timestamp() - interval '21 days', 1, 0)
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating, likes_count = EXCLUDED.likes_count;


INSERT INTO public.reviews (id, user_id, target_type, target_id, rating, body, author_display_name, status, version, created_at, updated_at)
VALUES ('00000000-0400-0000-0000-00000000000a', NULL, 'spot', '00000000-0100-0000-0000-00000000000a', 5, 'A must-visit Malaysian attraction. Stunning views, rich heritage, and very accessible. Arrive early to beat the crowd.', 'Demo Reviewer 04', 'published', 1, clock_timestamp() - interval '20 days', clock_timestamp() - interval '20 days')
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating;

INSERT INTO public.public_reviews (id, target_type, target_id, rating, body, author_display_name, version, created_at, updated_at, likes_count, dislikes_count)
VALUES ('00000000-0400-0000-0000-00000000000a', 'spot', '00000000-0100-0000-0000-00000000000a', 5, 'A must-visit Malaysian attraction. Stunning views, rich heritage, and very accessible. Arrive early to beat the crowd.', 'Demo Reviewer 04', 1, clock_timestamp() - interval '20 days', clock_timestamp() - interval '20 days', 2, 0)
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating, likes_count = EXCLUDED.likes_count;


INSERT INTO public.reviews (id, user_id, target_type, target_id, rating, body, author_display_name, status, version, created_at, updated_at)
VALUES ('00000000-0400-0000-0000-00000000000b', NULL, 'spot', '00000000-0100-0000-0000-00000000000b', 4, 'Great place for photography and family walks. The surrounding area has plenty of local refreshment options.', 'Demo Tourist', 'published', 1, clock_timestamp() - interval '19 days', clock_timestamp() - interval '19 days')
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating;

INSERT INTO public.public_reviews (id, target_type, target_id, rating, body, author_display_name, version, created_at, updated_at, likes_count, dislikes_count)
VALUES ('00000000-0400-0000-0000-00000000000b', 'spot', '00000000-0100-0000-0000-00000000000b', 4, 'Great place for photography and family walks. The surrounding area has plenty of local refreshment options.', 'Demo Tourist', 1, clock_timestamp() - interval '19 days', clock_timestamp() - interval '19 days', 3, 0)
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating, likes_count = EXCLUDED.likes_count;


INSERT INTO public.reviews (id, user_id, target_type, target_id, rating, body, author_display_name, status, version, created_at, updated_at)
VALUES ('00000000-0400-0000-0000-00000000000c', NULL, 'spot', '00000000-0100-0000-0000-00000000000c', 4, 'Fascinating historical significance and well-maintained pathways. Highly recommended for weekend explorers.', 'Demo Foodie', 'published', 1, clock_timestamp() - interval '18 days', clock_timestamp() - interval '18 days')
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating;

INSERT INTO public.public_reviews (id, target_type, target_id, rating, body, author_display_name, version, created_at, updated_at, likes_count, dislikes_count)
VALUES ('00000000-0400-0000-0000-00000000000c', 'spot', '00000000-0100-0000-0000-00000000000c', 4, 'Fascinating historical significance and well-maintained pathways. Highly recommended for weekend explorers.', 'Demo Foodie', 1, clock_timestamp() - interval '18 days', clock_timestamp() - interval '18 days', 4, 0)
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating, likes_count = EXCLUDED.likes_count;


INSERT INTO public.reviews (id, user_id, target_type, target_id, rating, body, author_display_name, status, version, created_at, updated_at)
VALUES ('00000000-0400-0000-0000-00000000000d', NULL, 'spot', '00000000-0100-0000-0000-00000000000d', 5, 'Incredible cultural experience! The architecture and peaceful atmosphere made our morning visit truly unforgettable.', 'Demo Reviewer 01', 'published', 1, clock_timestamp() - interval '17 days', clock_timestamp() - interval '17 days')
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating;

INSERT INTO public.public_reviews (id, target_type, target_id, rating, body, author_display_name, version, created_at, updated_at, likes_count, dislikes_count)
VALUES ('00000000-0400-0000-0000-00000000000d', 'spot', '00000000-0100-0000-0000-00000000000d', 5, 'Incredible cultural experience! The architecture and peaceful atmosphere made our morning visit truly unforgettable.', 'Demo Reviewer 01', 1, clock_timestamp() - interval '17 days', clock_timestamp() - interval '17 days', 5, 0)
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating, likes_count = EXCLUDED.likes_count;


INSERT INTO public.reviews (id, user_id, target_type, target_id, rating, body, author_display_name, status, version, created_at, updated_at)
VALUES ('00000000-0400-0000-0000-00000000000e', NULL, 'spot', '00000000-0100-0000-0000-00000000000e', 5, 'A must-visit Malaysian attraction. Stunning views, rich heritage, and very accessible. Arrive early to beat the crowd.', 'Demo Reviewer 02', 'published', 1, clock_timestamp() - interval '16 days', clock_timestamp() - interval '16 days')
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating;

INSERT INTO public.public_reviews (id, target_type, target_id, rating, body, author_display_name, version, created_at, updated_at, likes_count, dislikes_count)
VALUES ('00000000-0400-0000-0000-00000000000e', 'spot', '00000000-0100-0000-0000-00000000000e', 5, 'A must-visit Malaysian attraction. Stunning views, rich heritage, and very accessible. Arrive early to beat the crowd.', 'Demo Reviewer 02', 1, clock_timestamp() - interval '16 days', clock_timestamp() - interval '16 days', 6, 0)
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating, likes_count = EXCLUDED.likes_count;


INSERT INTO public.reviews (id, user_id, target_type, target_id, rating, body, author_display_name, status, version, created_at, updated_at)
VALUES ('00000000-0400-0000-0000-00000000000f', NULL, 'spot', '00000000-0100-0000-0000-00000000000f', 4, 'Great place for photography and family walks. The surrounding area has plenty of local refreshment options.', 'Demo Reviewer 03', 'published', 1, clock_timestamp() - interval '15 days', clock_timestamp() - interval '15 days')
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating;

INSERT INTO public.public_reviews (id, target_type, target_id, rating, body, author_display_name, version, created_at, updated_at, likes_count, dislikes_count)
VALUES ('00000000-0400-0000-0000-00000000000f', 'spot', '00000000-0100-0000-0000-00000000000f', 4, 'Great place for photography and family walks. The surrounding area has plenty of local refreshment options.', 'Demo Reviewer 03', 1, clock_timestamp() - interval '15 days', clock_timestamp() - interval '15 days', 7, 0)
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating, likes_count = EXCLUDED.likes_count;


INSERT INTO public.reviews (id, user_id, target_type, target_id, rating, body, author_display_name, status, version, created_at, updated_at)
VALUES ('00000000-0400-0000-0000-000000000010', NULL, 'spot', '00000000-0100-0000-0000-000000000010', 4, 'Fascinating historical significance and well-maintained pathways. Highly recommended for weekend explorers.', 'Demo Reviewer 04', 'published', 1, clock_timestamp() - interval '14 days', clock_timestamp() - interval '14 days')
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating;

INSERT INTO public.public_reviews (id, target_type, target_id, rating, body, author_display_name, version, created_at, updated_at, likes_count, dislikes_count)
VALUES ('00000000-0400-0000-0000-000000000010', 'spot', '00000000-0100-0000-0000-000000000010', 4, 'Fascinating historical significance and well-maintained pathways. Highly recommended for weekend explorers.', 'Demo Reviewer 04', 1, clock_timestamp() - interval '14 days', clock_timestamp() - interval '14 days', 0, 0)
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating, likes_count = EXCLUDED.likes_count;


INSERT INTO public.reviews (id, user_id, target_type, target_id, rating, body, author_display_name, status, version, created_at, updated_at)
VALUES ('00000000-0400-0000-0000-000000000011', NULL, 'spot', '00000000-0100-0000-0000-000000000011', 5, 'Incredible cultural experience! The architecture and peaceful atmosphere made our morning visit truly unforgettable.', 'Demo Tourist', 'published', 1, clock_timestamp() - interval '13 days', clock_timestamp() - interval '13 days')
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating;

INSERT INTO public.public_reviews (id, target_type, target_id, rating, body, author_display_name, version, created_at, updated_at, likes_count, dislikes_count)
VALUES ('00000000-0400-0000-0000-000000000011', 'spot', '00000000-0100-0000-0000-000000000011', 5, 'Incredible cultural experience! The architecture and peaceful atmosphere made our morning visit truly unforgettable.', 'Demo Tourist', 1, clock_timestamp() - interval '13 days', clock_timestamp() - interval '13 days', 1, 0)
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating, likes_count = EXCLUDED.likes_count;


INSERT INTO public.reviews (id, user_id, target_type, target_id, rating, body, author_display_name, status, version, created_at, updated_at)
VALUES ('00000000-0400-0000-0000-000000000012', NULL, 'spot', '00000000-0100-0000-0000-000000000012', 5, 'A must-visit Malaysian attraction. Stunning views, rich heritage, and very accessible. Arrive early to beat the crowd.', 'Demo Foodie', 'published', 1, clock_timestamp() - interval '12 days', clock_timestamp() - interval '12 days')
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating;

INSERT INTO public.public_reviews (id, target_type, target_id, rating, body, author_display_name, version, created_at, updated_at, likes_count, dislikes_count)
VALUES ('00000000-0400-0000-0000-000000000012', 'spot', '00000000-0100-0000-0000-000000000012', 5, 'A must-visit Malaysian attraction. Stunning views, rich heritage, and very accessible. Arrive early to beat the crowd.', 'Demo Foodie', 1, clock_timestamp() - interval '12 days', clock_timestamp() - interval '12 days', 2, 0)
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating, likes_count = EXCLUDED.likes_count;


INSERT INTO public.reviews (id, user_id, target_type, target_id, rating, body, author_display_name, status, version, created_at, updated_at)
VALUES ('00000000-0400-0000-0000-000000000013', NULL, 'spot', '00000000-0100-0000-0000-000000000013', 4, 'Great place for photography and family walks. The surrounding area has plenty of local refreshment options.', 'Demo Reviewer 01', 'published', 1, clock_timestamp() - interval '11 days', clock_timestamp() - interval '11 days')
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating;

INSERT INTO public.public_reviews (id, target_type, target_id, rating, body, author_display_name, version, created_at, updated_at, likes_count, dislikes_count)
VALUES ('00000000-0400-0000-0000-000000000013', 'spot', '00000000-0100-0000-0000-000000000013', 4, 'Great place for photography and family walks. The surrounding area has plenty of local refreshment options.', 'Demo Reviewer 01', 1, clock_timestamp() - interval '11 days', clock_timestamp() - interval '11 days', 3, 0)
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating, likes_count = EXCLUDED.likes_count;


INSERT INTO public.reviews (id, user_id, target_type, target_id, rating, body, author_display_name, status, version, created_at, updated_at)
VALUES ('00000000-0400-0000-0000-000000000014', NULL, 'spot', '00000000-0100-0000-0000-000000000014', 4, 'Fascinating historical significance and well-maintained pathways. Highly recommended for weekend explorers.', 'Demo Reviewer 02', 'published', 1, clock_timestamp() - interval '10 days', clock_timestamp() - interval '10 days')
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating;

INSERT INTO public.public_reviews (id, target_type, target_id, rating, body, author_display_name, version, created_at, updated_at, likes_count, dislikes_count)
VALUES ('00000000-0400-0000-0000-000000000014', 'spot', '00000000-0100-0000-0000-000000000014', 4, 'Fascinating historical significance and well-maintained pathways. Highly recommended for weekend explorers.', 'Demo Reviewer 02', 1, clock_timestamp() - interval '10 days', clock_timestamp() - interval '10 days', 4, 0)
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating, likes_count = EXCLUDED.likes_count;


INSERT INTO public.reviews (id, user_id, target_type, target_id, rating, body, author_display_name, status, version, created_at, updated_at)
VALUES ('00000000-0400-0000-0000-000000000015', NULL, 'spot', '00000000-0100-0000-0000-000000000015', 5, 'Incredible cultural experience! The architecture and peaceful atmosphere made our morning visit truly unforgettable.', 'Demo Reviewer 03', 'published', 1, clock_timestamp() - interval '9 days', clock_timestamp() - interval '9 days')
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating;

INSERT INTO public.public_reviews (id, target_type, target_id, rating, body, author_display_name, version, created_at, updated_at, likes_count, dislikes_count)
VALUES ('00000000-0400-0000-0000-000000000015', 'spot', '00000000-0100-0000-0000-000000000015', 5, 'Incredible cultural experience! The architecture and peaceful atmosphere made our morning visit truly unforgettable.', 'Demo Reviewer 03', 1, clock_timestamp() - interval '9 days', clock_timestamp() - interval '9 days', 5, 0)
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating, likes_count = EXCLUDED.likes_count;


INSERT INTO public.reviews (id, user_id, target_type, target_id, rating, body, author_display_name, status, version, created_at, updated_at)
VALUES ('00000000-0400-0000-0000-000000000016', NULL, 'spot', '00000000-0100-0000-0000-000000000016', 5, 'A must-visit Malaysian attraction. Stunning views, rich heritage, and very accessible. Arrive early to beat the crowd.', 'Demo Reviewer 04', 'published', 1, clock_timestamp() - interval '8 days', clock_timestamp() - interval '8 days')
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating;

INSERT INTO public.public_reviews (id, target_type, target_id, rating, body, author_display_name, version, created_at, updated_at, likes_count, dislikes_count)
VALUES ('00000000-0400-0000-0000-000000000016', 'spot', '00000000-0100-0000-0000-000000000016', 5, 'A must-visit Malaysian attraction. Stunning views, rich heritage, and very accessible. Arrive early to beat the crowd.', 'Demo Reviewer 04', 1, clock_timestamp() - interval '8 days', clock_timestamp() - interval '8 days', 6, 0)
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating, likes_count = EXCLUDED.likes_count;


INSERT INTO public.reviews (id, user_id, target_type, target_id, rating, body, author_display_name, status, version, created_at, updated_at)
VALUES ('00000000-0400-0000-0000-000000000017', NULL, 'spot', '00000000-0100-0000-0000-000000000017', 4, 'Great place for photography and family walks. The surrounding area has plenty of local refreshment options.', 'Demo Tourist', 'published', 1, clock_timestamp() - interval '7 days', clock_timestamp() - interval '7 days')
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating;

INSERT INTO public.public_reviews (id, target_type, target_id, rating, body, author_display_name, version, created_at, updated_at, likes_count, dislikes_count)
VALUES ('00000000-0400-0000-0000-000000000017', 'spot', '00000000-0100-0000-0000-000000000017', 4, 'Great place for photography and family walks. The surrounding area has plenty of local refreshment options.', 'Demo Tourist', 1, clock_timestamp() - interval '7 days', clock_timestamp() - interval '7 days', 7, 0)
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating, likes_count = EXCLUDED.likes_count;


INSERT INTO public.reviews (id, user_id, target_type, target_id, rating, body, author_display_name, status, version, created_at, updated_at)
VALUES ('00000000-0400-0000-0000-000000000018', NULL, 'spot', '00000000-0100-0000-0000-000000000018', 4, 'Fascinating historical significance and well-maintained pathways. Highly recommended for weekend explorers.', 'Demo Foodie', 'published', 1, clock_timestamp() - interval '6 days', clock_timestamp() - interval '6 days')
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating;

INSERT INTO public.public_reviews (id, target_type, target_id, rating, body, author_display_name, version, created_at, updated_at, likes_count, dislikes_count)
VALUES ('00000000-0400-0000-0000-000000000018', 'spot', '00000000-0100-0000-0000-000000000018', 4, 'Fascinating historical significance and well-maintained pathways. Highly recommended for weekend explorers.', 'Demo Foodie', 1, clock_timestamp() - interval '6 days', clock_timestamp() - interval '6 days', 0, 0)
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating, likes_count = EXCLUDED.likes_count;


INSERT INTO public.reviews (id, user_id, target_type, target_id, rating, body, author_display_name, status, version, created_at, updated_at)
VALUES ('00000000-0400-0000-0000-000000000019', NULL, 'restaurant', '00000000-0200-0000-0000-000000000001', 5, 'Authentic flavours that live up to the legendary reputation! The signature dish was cooked to absolute perfection.', 'Demo Reviewer 01', 'published', 1, clock_timestamp() - interval '24 days', clock_timestamp() - interval '24 days')
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating;

INSERT INTO public.public_reviews (id, target_type, target_id, rating, body, author_display_name, version, created_at, updated_at, likes_count, dislikes_count)
VALUES ('00000000-0400-0000-0000-000000000019', 'restaurant', '00000000-0200-0000-0000-000000000001', 5, 'Authentic flavours that live up to the legendary reputation! The signature dish was cooked to absolute perfection.', 'Demo Reviewer 01', 1, clock_timestamp() - interval '24 days', clock_timestamp() - interval '24 days', 1, 0)
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating, likes_count = EXCLUDED.likes_count;


INSERT INTO public.reviews (id, user_id, target_type, target_id, rating, body, author_display_name, status, version, created_at, updated_at)
VALUES ('00000000-0400-0000-0000-00000000001a', NULL, 'restaurant', '00000000-0200-0000-0000-000000000002', 5, 'Wonderful heritage taste with warm, fast service. Definitely worth waiting in line for.', 'Demo Reviewer 02', 'published', 1, clock_timestamp() - interval '23 days', clock_timestamp() - interval '23 days')
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating;

INSERT INTO public.public_reviews (id, target_type, target_id, rating, body, author_display_name, version, created_at, updated_at, likes_count, dislikes_count)
VALUES ('00000000-0400-0000-0000-00000000001a', 'restaurant', '00000000-0200-0000-0000-000000000002', 5, 'Wonderful heritage taste with warm, fast service. Definitely worth waiting in line for.', 'Demo Reviewer 02', 1, clock_timestamp() - interval '23 days', clock_timestamp() - interval '23 days', 2, 0)
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating, likes_count = EXCLUDED.likes_count;


INSERT INTO public.reviews (id, user_id, target_type, target_id, rating, body, author_display_name, status, version, created_at, updated_at)
VALUES ('00000000-0400-0000-0000-00000000001b', NULL, 'restaurant', '00000000-0200-0000-0000-000000000003', 4, 'Generous portions and very reasonable pricing. The balance of spices and fresh ingredients is remarkable.', 'Demo Reviewer 03', 'published', 1, clock_timestamp() - interval '22 days', clock_timestamp() - interval '22 days')
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating;

INSERT INTO public.public_reviews (id, target_type, target_id, rating, body, author_display_name, version, created_at, updated_at, likes_count, dislikes_count)
VALUES ('00000000-0400-0000-0000-00000000001b', 'restaurant', '00000000-0200-0000-0000-000000000003', 4, 'Generous portions and very reasonable pricing. The balance of spices and fresh ingredients is remarkable.', 'Demo Reviewer 03', 1, clock_timestamp() - interval '22 days', clock_timestamp() - interval '22 days', 3, 0)
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating, likes_count = EXCLUDED.likes_count;


INSERT INTO public.reviews (id, user_id, target_type, target_id, rating, body, author_display_name, status, version, created_at, updated_at)
VALUES ('00000000-0400-0000-0000-00000000001c', NULL, 'restaurant', '00000000-0200-0000-0000-000000000004', 4, 'Classic Malaysian comfort food at its best. Loved the traditional kopitiam ambiance and aroma.', 'Demo Reviewer 04', 'published', 1, clock_timestamp() - interval '21 days', clock_timestamp() - interval '21 days')
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating;

INSERT INTO public.public_reviews (id, target_type, target_id, rating, body, author_display_name, version, created_at, updated_at, likes_count, dislikes_count)
VALUES ('00000000-0400-0000-0000-00000000001c', 'restaurant', '00000000-0200-0000-0000-000000000004', 4, 'Classic Malaysian comfort food at its best. Loved the traditional kopitiam ambiance and aroma.', 'Demo Reviewer 04', 1, clock_timestamp() - interval '21 days', clock_timestamp() - interval '21 days', 4, 0)
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating, likes_count = EXCLUDED.likes_count;


INSERT INTO public.reviews (id, user_id, target_type, target_id, rating, body, author_display_name, status, version, created_at, updated_at)
VALUES ('00000000-0400-0000-0000-00000000001d', NULL, 'restaurant', '00000000-0200-0000-0000-000000000005', 5, 'Authentic flavours that live up to the legendary reputation! The signature dish was cooked to absolute perfection.', 'Demo Tourist', 'published', 1, clock_timestamp() - interval '20 days', clock_timestamp() - interval '20 days')
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating;

INSERT INTO public.public_reviews (id, target_type, target_id, rating, body, author_display_name, version, created_at, updated_at, likes_count, dislikes_count)
VALUES ('00000000-0400-0000-0000-00000000001d', 'restaurant', '00000000-0200-0000-0000-000000000005', 5, 'Authentic flavours that live up to the legendary reputation! The signature dish was cooked to absolute perfection.', 'Demo Tourist', 1, clock_timestamp() - interval '20 days', clock_timestamp() - interval '20 days', 5, 0)
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating, likes_count = EXCLUDED.likes_count;


INSERT INTO public.reviews (id, user_id, target_type, target_id, rating, body, author_display_name, status, version, created_at, updated_at)
VALUES ('00000000-0400-0000-0000-00000000001e', NULL, 'restaurant', '00000000-0200-0000-0000-000000000006', 5, 'Wonderful heritage taste with warm, fast service. Definitely worth waiting in line for.', 'Demo Foodie', 'published', 1, clock_timestamp() - interval '19 days', clock_timestamp() - interval '19 days')
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating;

INSERT INTO public.public_reviews (id, target_type, target_id, rating, body, author_display_name, version, created_at, updated_at, likes_count, dislikes_count)
VALUES ('00000000-0400-0000-0000-00000000001e', 'restaurant', '00000000-0200-0000-0000-000000000006', 5, 'Wonderful heritage taste with warm, fast service. Definitely worth waiting in line for.', 'Demo Foodie', 1, clock_timestamp() - interval '19 days', clock_timestamp() - interval '19 days', 0, 0)
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating, likes_count = EXCLUDED.likes_count;


INSERT INTO public.reviews (id, user_id, target_type, target_id, rating, body, author_display_name, status, version, created_at, updated_at)
VALUES ('00000000-0400-0000-0000-00000000001f', NULL, 'restaurant', '00000000-0200-0000-0000-000000000007', 4, 'Generous portions and very reasonable pricing. The balance of spices and fresh ingredients is remarkable.', 'Demo Reviewer 01', 'published', 1, clock_timestamp() - interval '18 days', clock_timestamp() - interval '18 days')
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating;

INSERT INTO public.public_reviews (id, target_type, target_id, rating, body, author_display_name, version, created_at, updated_at, likes_count, dislikes_count)
VALUES ('00000000-0400-0000-0000-00000000001f', 'restaurant', '00000000-0200-0000-0000-000000000007', 4, 'Generous portions and very reasonable pricing. The balance of spices and fresh ingredients is remarkable.', 'Demo Reviewer 01', 1, clock_timestamp() - interval '18 days', clock_timestamp() - interval '18 days', 1, 0)
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating, likes_count = EXCLUDED.likes_count;


INSERT INTO public.reviews (id, user_id, target_type, target_id, rating, body, author_display_name, status, version, created_at, updated_at)
VALUES ('00000000-0400-0000-0000-000000000020', NULL, 'restaurant', '00000000-0200-0000-0000-000000000008', 4, 'Classic Malaysian comfort food at its best. Loved the traditional kopitiam ambiance and aroma.', 'Demo Reviewer 02', 'published', 1, clock_timestamp() - interval '17 days', clock_timestamp() - interval '17 days')
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating;

INSERT INTO public.public_reviews (id, target_type, target_id, rating, body, author_display_name, version, created_at, updated_at, likes_count, dislikes_count)
VALUES ('00000000-0400-0000-0000-000000000020', 'restaurant', '00000000-0200-0000-0000-000000000008', 4, 'Classic Malaysian comfort food at its best. Loved the traditional kopitiam ambiance and aroma.', 'Demo Reviewer 02', 1, clock_timestamp() - interval '17 days', clock_timestamp() - interval '17 days', 2, 0)
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating, likes_count = EXCLUDED.likes_count;


INSERT INTO public.reviews (id, user_id, target_type, target_id, rating, body, author_display_name, status, version, created_at, updated_at)
VALUES ('00000000-0400-0000-0000-000000000021', NULL, 'restaurant', '00000000-0200-0000-0000-000000000009', 5, 'Authentic flavours that live up to the legendary reputation! The signature dish was cooked to absolute perfection.', 'Demo Reviewer 03', 'published', 1, clock_timestamp() - interval '16 days', clock_timestamp() - interval '16 days')
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating;

INSERT INTO public.public_reviews (id, target_type, target_id, rating, body, author_display_name, version, created_at, updated_at, likes_count, dislikes_count)
VALUES ('00000000-0400-0000-0000-000000000021', 'restaurant', '00000000-0200-0000-0000-000000000009', 5, 'Authentic flavours that live up to the legendary reputation! The signature dish was cooked to absolute perfection.', 'Demo Reviewer 03', 1, clock_timestamp() - interval '16 days', clock_timestamp() - interval '16 days', 3, 0)
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating, likes_count = EXCLUDED.likes_count;


INSERT INTO public.reviews (id, user_id, target_type, target_id, rating, body, author_display_name, status, version, created_at, updated_at)
VALUES ('00000000-0400-0000-0000-000000000022', NULL, 'restaurant', '00000000-0200-0000-0000-00000000000a', 5, 'Wonderful heritage taste with warm, fast service. Definitely worth waiting in line for.', 'Demo Reviewer 04', 'published', 1, clock_timestamp() - interval '15 days', clock_timestamp() - interval '15 days')
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating;

INSERT INTO public.public_reviews (id, target_type, target_id, rating, body, author_display_name, version, created_at, updated_at, likes_count, dislikes_count)
VALUES ('00000000-0400-0000-0000-000000000022', 'restaurant', '00000000-0200-0000-0000-00000000000a', 5, 'Wonderful heritage taste with warm, fast service. Definitely worth waiting in line for.', 'Demo Reviewer 04', 1, clock_timestamp() - interval '15 days', clock_timestamp() - interval '15 days', 4, 0)
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating, likes_count = EXCLUDED.likes_count;


INSERT INTO public.reviews (id, user_id, target_type, target_id, rating, body, author_display_name, status, version, created_at, updated_at)
VALUES ('00000000-0400-0000-0000-000000000023', NULL, 'restaurant', '00000000-0200-0000-0000-00000000000b', 4, 'Generous portions and very reasonable pricing. The balance of spices and fresh ingredients is remarkable.', 'Demo Tourist', 'published', 1, clock_timestamp() - interval '14 days', clock_timestamp() - interval '14 days')
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating;

INSERT INTO public.public_reviews (id, target_type, target_id, rating, body, author_display_name, version, created_at, updated_at, likes_count, dislikes_count)
VALUES ('00000000-0400-0000-0000-000000000023', 'restaurant', '00000000-0200-0000-0000-00000000000b', 4, 'Generous portions and very reasonable pricing. The balance of spices and fresh ingredients is remarkable.', 'Demo Tourist', 1, clock_timestamp() - interval '14 days', clock_timestamp() - interval '14 days', 5, 0)
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating, likes_count = EXCLUDED.likes_count;


INSERT INTO public.reviews (id, user_id, target_type, target_id, rating, body, author_display_name, status, version, created_at, updated_at)
VALUES ('00000000-0400-0000-0000-000000000024', NULL, 'restaurant', '00000000-0200-0000-0000-00000000000c', 4, 'Classic Malaysian comfort food at its best. Loved the traditional kopitiam ambiance and aroma.', 'Demo Foodie', 'published', 1, clock_timestamp() - interval '13 days', clock_timestamp() - interval '13 days')
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating;

INSERT INTO public.public_reviews (id, target_type, target_id, rating, body, author_display_name, version, created_at, updated_at, likes_count, dislikes_count)
VALUES ('00000000-0400-0000-0000-000000000024', 'restaurant', '00000000-0200-0000-0000-00000000000c', 4, 'Classic Malaysian comfort food at its best. Loved the traditional kopitiam ambiance and aroma.', 'Demo Foodie', 1, clock_timestamp() - interval '13 days', clock_timestamp() - interval '13 days', 0, 0)
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating, likes_count = EXCLUDED.likes_count;


INSERT INTO public.reviews (id, user_id, target_type, target_id, rating, body, author_display_name, status, version, created_at, updated_at)
VALUES ('00000000-0400-0000-0000-000000000025', NULL, 'restaurant', '00000000-0200-0000-0000-00000000000d', 5, 'Authentic flavours that live up to the legendary reputation! The signature dish was cooked to absolute perfection.', 'Demo Reviewer 01', 'published', 1, clock_timestamp() - interval '12 days', clock_timestamp() - interval '12 days')
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating;

INSERT INTO public.public_reviews (id, target_type, target_id, rating, body, author_display_name, version, created_at, updated_at, likes_count, dislikes_count)
VALUES ('00000000-0400-0000-0000-000000000025', 'restaurant', '00000000-0200-0000-0000-00000000000d', 5, 'Authentic flavours that live up to the legendary reputation! The signature dish was cooked to absolute perfection.', 'Demo Reviewer 01', 1, clock_timestamp() - interval '12 days', clock_timestamp() - interval '12 days', 1, 0)
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating, likes_count = EXCLUDED.likes_count;


INSERT INTO public.reviews (id, user_id, target_type, target_id, rating, body, author_display_name, status, version, created_at, updated_at)
VALUES ('00000000-0400-0000-0000-000000000026', NULL, 'restaurant', '00000000-0200-0000-0000-00000000000e', 5, 'Wonderful heritage taste with warm, fast service. Definitely worth waiting in line for.', 'Demo Reviewer 02', 'published', 1, clock_timestamp() - interval '11 days', clock_timestamp() - interval '11 days')
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating;

INSERT INTO public.public_reviews (id, target_type, target_id, rating, body, author_display_name, version, created_at, updated_at, likes_count, dislikes_count)
VALUES ('00000000-0400-0000-0000-000000000026', 'restaurant', '00000000-0200-0000-0000-00000000000e', 5, 'Wonderful heritage taste with warm, fast service. Definitely worth waiting in line for.', 'Demo Reviewer 02', 1, clock_timestamp() - interval '11 days', clock_timestamp() - interval '11 days', 2, 0)
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating, likes_count = EXCLUDED.likes_count;


INSERT INTO public.reviews (id, user_id, target_type, target_id, rating, body, author_display_name, status, version, created_at, updated_at)
VALUES ('00000000-0400-0000-0000-000000000027', NULL, 'restaurant', '00000000-0200-0000-0000-00000000000f', 4, 'Generous portions and very reasonable pricing. The balance of spices and fresh ingredients is remarkable.', 'Demo Reviewer 03', 'published', 1, clock_timestamp() - interval '10 days', clock_timestamp() - interval '10 days')
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating;

INSERT INTO public.public_reviews (id, target_type, target_id, rating, body, author_display_name, version, created_at, updated_at, likes_count, dislikes_count)
VALUES ('00000000-0400-0000-0000-000000000027', 'restaurant', '00000000-0200-0000-0000-00000000000f', 4, 'Generous portions and very reasonable pricing. The balance of spices and fresh ingredients is remarkable.', 'Demo Reviewer 03', 1, clock_timestamp() - interval '10 days', clock_timestamp() - interval '10 days', 3, 0)
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating, likes_count = EXCLUDED.likes_count;


INSERT INTO public.reviews (id, user_id, target_type, target_id, rating, body, author_display_name, status, version, created_at, updated_at)
VALUES ('00000000-0400-0000-0000-000000000028', NULL, 'restaurant', '00000000-0200-0000-0000-000000000010', 4, 'Classic Malaysian comfort food at its best. Loved the traditional kopitiam ambiance and aroma.', 'Demo Reviewer 04', 'published', 1, clock_timestamp() - interval '9 days', clock_timestamp() - interval '9 days')
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating;

INSERT INTO public.public_reviews (id, target_type, target_id, rating, body, author_display_name, version, created_at, updated_at, likes_count, dislikes_count)
VALUES ('00000000-0400-0000-0000-000000000028', 'restaurant', '00000000-0200-0000-0000-000000000010', 4, 'Classic Malaysian comfort food at its best. Loved the traditional kopitiam ambiance and aroma.', 'Demo Reviewer 04', 1, clock_timestamp() - interval '9 days', clock_timestamp() - interval '9 days', 4, 0)
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating, likes_count = EXCLUDED.likes_count;


INSERT INTO public.reviews (id, user_id, target_type, target_id, rating, body, author_display_name, status, version, created_at, updated_at)
VALUES ('00000000-0400-0000-0000-000000000029', NULL, 'restaurant', '00000000-0200-0000-0000-000000000011', 5, 'Authentic flavours that live up to the legendary reputation! The signature dish was cooked to absolute perfection.', 'Demo Tourist', 'published', 1, clock_timestamp() - interval '8 days', clock_timestamp() - interval '8 days')
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating;

INSERT INTO public.public_reviews (id, target_type, target_id, rating, body, author_display_name, version, created_at, updated_at, likes_count, dislikes_count)
VALUES ('00000000-0400-0000-0000-000000000029', 'restaurant', '00000000-0200-0000-0000-000000000011', 5, 'Authentic flavours that live up to the legendary reputation! The signature dish was cooked to absolute perfection.', 'Demo Tourist', 1, clock_timestamp() - interval '8 days', clock_timestamp() - interval '8 days', 5, 0)
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating, likes_count = EXCLUDED.likes_count;


INSERT INTO public.reviews (id, user_id, target_type, target_id, rating, body, author_display_name, status, version, created_at, updated_at)
VALUES ('00000000-0400-0000-0000-00000000002a', NULL, 'restaurant', '00000000-0200-0000-0000-000000000012', 5, 'Wonderful heritage taste with warm, fast service. Definitely worth waiting in line for.', 'Demo Foodie', 'published', 1, clock_timestamp() - interval '7 days', clock_timestamp() - interval '7 days')
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating;

INSERT INTO public.public_reviews (id, target_type, target_id, rating, body, author_display_name, version, created_at, updated_at, likes_count, dislikes_count)
VALUES ('00000000-0400-0000-0000-00000000002a', 'restaurant', '00000000-0200-0000-0000-000000000012', 5, 'Wonderful heritage taste with warm, fast service. Definitely worth waiting in line for.', 'Demo Foodie', 1, clock_timestamp() - interval '7 days', clock_timestamp() - interval '7 days', 0, 0)
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating, likes_count = EXCLUDED.likes_count;


INSERT INTO public.reviews (id, user_id, target_type, target_id, rating, body, author_display_name, status, version, created_at, updated_at)
VALUES ('00000000-0400-0000-0000-00000000002b', NULL, 'restaurant', '00000000-0200-0000-0000-000000000013', 4, 'Generous portions and very reasonable pricing. The balance of spices and fresh ingredients is remarkable.', 'Demo Reviewer 01', 'published', 1, clock_timestamp() - interval '6 days', clock_timestamp() - interval '6 days')
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating;

INSERT INTO public.public_reviews (id, target_type, target_id, rating, body, author_display_name, version, created_at, updated_at, likes_count, dislikes_count)
VALUES ('00000000-0400-0000-0000-00000000002b', 'restaurant', '00000000-0200-0000-0000-000000000013', 4, 'Generous portions and very reasonable pricing. The balance of spices and fresh ingredients is remarkable.', 'Demo Reviewer 01', 1, clock_timestamp() - interval '6 days', clock_timestamp() - interval '6 days', 1, 0)
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating, likes_count = EXCLUDED.likes_count;


INSERT INTO public.reviews (id, user_id, target_type, target_id, rating, body, author_display_name, status, version, created_at, updated_at)
VALUES ('00000000-0400-0000-0000-00000000002c', NULL, 'restaurant', '00000000-0200-0000-0000-000000000014', 4, 'Classic Malaysian comfort food at its best. Loved the traditional kopitiam ambiance and aroma.', 'Demo Reviewer 02', 'published', 1, clock_timestamp() - interval '5 days', clock_timestamp() - interval '5 days')
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating;

INSERT INTO public.public_reviews (id, target_type, target_id, rating, body, author_display_name, version, created_at, updated_at, likes_count, dislikes_count)
VALUES ('00000000-0400-0000-0000-00000000002c', 'restaurant', '00000000-0200-0000-0000-000000000014', 4, 'Classic Malaysian comfort food at its best. Loved the traditional kopitiam ambiance and aroma.', 'Demo Reviewer 02', 1, clock_timestamp() - interval '5 days', clock_timestamp() - interval '5 days', 2, 0)
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating, likes_count = EXCLUDED.likes_count;


INSERT INTO public.reviews (id, user_id, target_type, target_id, rating, body, author_display_name, status, version, created_at, updated_at)
VALUES ('00000000-0400-0000-0000-00000000002d', NULL, 'restaurant', '00000000-0200-0000-0000-000000000015', 5, 'Authentic flavours that live up to the legendary reputation! The signature dish was cooked to absolute perfection.', 'Demo Reviewer 03', 'published', 1, clock_timestamp() - interval '4 days', clock_timestamp() - interval '4 days')
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating;

INSERT INTO public.public_reviews (id, target_type, target_id, rating, body, author_display_name, version, created_at, updated_at, likes_count, dislikes_count)
VALUES ('00000000-0400-0000-0000-00000000002d', 'restaurant', '00000000-0200-0000-0000-000000000015', 5, 'Authentic flavours that live up to the legendary reputation! The signature dish was cooked to absolute perfection.', 'Demo Reviewer 03', 1, clock_timestamp() - interval '4 days', clock_timestamp() - interval '4 days', 3, 0)
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating, likes_count = EXCLUDED.likes_count;


INSERT INTO public.reviews (id, user_id, target_type, target_id, rating, body, author_display_name, status, version, created_at, updated_at)
VALUES ('00000000-0400-0000-0000-00000000002e', NULL, 'restaurant', '00000000-0200-0000-0000-000000000016', 5, 'Wonderful heritage taste with warm, fast service. Definitely worth waiting in line for.', 'Demo Reviewer 04', 'published', 1, clock_timestamp() - interval '3 days', clock_timestamp() - interval '3 days')
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating;

INSERT INTO public.public_reviews (id, target_type, target_id, rating, body, author_display_name, version, created_at, updated_at, likes_count, dislikes_count)
VALUES ('00000000-0400-0000-0000-00000000002e', 'restaurant', '00000000-0200-0000-0000-000000000016', 5, 'Wonderful heritage taste with warm, fast service. Definitely worth waiting in line for.', 'Demo Reviewer 04', 1, clock_timestamp() - interval '3 days', clock_timestamp() - interval '3 days', 4, 0)
ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, rating = EXCLUDED.rating, likes_count = EXCLUDED.likes_count;


-- 5. SYNTHETIC MODERATION QUEUE CASES (6 Harmless Moderation Reports)

INSERT INTO public.moderation_cases (id, reporter_id, target_type, target_id, reason, explanation, status, version, created_at, updated_at)
VALUES ('00000000-0500-0000-0000-000000000001', NULL, 'spot', '00000000-0100-0000-0000-000000000001', 'misleading', 'Possible duplicate listing found under alternative transliterated name.', 'pending'::public.moderation_case_status, 1, clock_timestamp() - interval '6 days', clock_timestamp() - interval '6 days')
ON CONFLICT (id) DO UPDATE SET reason = EXCLUDED.reason, explanation = EXCLUDED.explanation, status = EXCLUDED.status;


INSERT INTO public.moderation_cases (id, reporter_id, target_type, target_id, reason, explanation, status, version, created_at, updated_at)
VALUES ('00000000-0500-0000-0000-000000000002', NULL, 'spot', '00000000-0100-0000-0000-000000000009', 'misleading', 'The cover image shows older construction scaffolding that has since been removed.', 'pending'::public.moderation_case_status, 1, clock_timestamp() - interval '5 days', clock_timestamp() - interval '5 days')
ON CONFLICT (id) DO UPDATE SET reason = EXCLUDED.reason, explanation = EXCLUDED.explanation, status = EXCLUDED.status;


INSERT INTO public.moderation_cases (id, reporter_id, target_type, target_id, reason, explanation, status, version, created_at, updated_at)
VALUES ('00000000-0500-0000-0000-000000000003', NULL, 'restaurant', '00000000-0200-0000-0000-000000000004', 'misleading', 'The street number appears slightly offset from the main entrance lobby.', 'under_review'::public.moderation_case_status, 1, clock_timestamp() - interval '4 days', clock_timestamp() - interval '4 days')
ON CONFLICT (id) DO UPDATE SET reason = EXCLUDED.reason, explanation = EXCLUDED.explanation, status = EXCLUDED.status;


INSERT INTO public.moderation_cases (id, reporter_id, target_type, target_id, reason, explanation, status, version, created_at, updated_at)
VALUES ('00000000-0500-0000-0000-000000000004', NULL, 'restaurant', '00000000-0200-0000-0000-00000000000a', 'other', 'Operating hours on public holidays may differ from normal weekday hours.', 'pending'::public.moderation_case_status, 1, clock_timestamp() - interval '3 days', clock_timestamp() - interval '3 days')
ON CONFLICT (id) DO UPDATE SET reason = EXCLUDED.reason, explanation = EXCLUDED.explanation, status = EXCLUDED.status;


INSERT INTO public.moderation_cases (id, reporter_id, target_type, target_id, reason, explanation, status, version, created_at, updated_at)
VALUES ('00000000-0500-0000-0000-000000000005', NULL, 'guide', '00000000-0300-0000-0000-000000000002', 'other', 'Suggest adding landmark navigation tip for the river crossing bridge.', 'pending'::public.moderation_case_status, 1, clock_timestamp() - interval '2 days', clock_timestamp() - interval '2 days')
ON CONFLICT (id) DO UPDATE SET reason = EXCLUDED.reason, explanation = EXCLUDED.explanation, status = EXCLUDED.status;


INSERT INTO public.moderation_cases (id, reporter_id, target_type, target_id, reason, explanation, status, version, created_at, updated_at)
VALUES ('00000000-0500-0000-0000-000000000006', NULL, 'review', '00000000-0400-0000-0000-000000000001', 'spam', 'Review mentions unrelated parking lot operator outside the main attraction grounds.', 'pending'::public.moderation_case_status, 1, clock_timestamp() - interval '1 days', clock_timestamp() - interval '1 days')
ON CONFLICT (id) DO UPDATE SET reason = EXCLUDED.reason, explanation = EXCLUDED.explanation, status = EXCLUDED.status;

COMMIT;
