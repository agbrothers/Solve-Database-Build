-- Define all tables and relations in the Solve Database (MySQL)
create database solve;


-- ROOT TABLE
create table users(
	user_id char(36) not null,
	user_creation_time datetime not null,
	language varchar(30),
    	retention_id int,
    	ab_test_id int,
	location_id int,
	gender_id int,
	device_id int,
	primary key (user_id)
);


-- LOOKUP TABLES
create table locations(
	id int auto_increment not null,
	city varchar(50) not null,
	country varchar(50) not null,
	primary key (id)
);

create table genders(
	id int auto_increment not null,
	gender varchar(10) not null,
	primary key (id)
);

create table retention(
	id int auto_increment not null,
	dn varchar(6) not null,
	primary key (id)
);


create table ab_tests(
	id int auto_increment not null,
	test varchar(40) not null,
	test_group varchar(40) not null,
	primary key (id)
);

create table devices(
	id int auto_increment not null,
	device_model varchar(30),	
	device_manufacturer varchar(30),
	device_family varchar(30),
	device_carrier varchar(30),
	device_type varchar(30),
	platform varchar(30),
	os_name varchar(10),
	os_version varchar(30),
	primary key (id)
);

create table event_types(
	id int auto_increment not null,
	type varchar(20),
	primary key (id)
);

create table characters(
	id int auto_increment not null,
	name varchar(20),
	primary key (id)
);


-- EVENT PROPERTY TABLES
create table events(
	id int auto_increment not null,
	user_id char(36) not null,
	time datetime not null,
	primary key (id),
	foreign key (user_id) references users(user_id) on delete cascade
);

create table user_properties(
	id int auto_increment not null,
	user_id char(36) not null,
	event_id int not null,
	current_ab_test_group VARCHAR(40),
	total_session_count INT,
	current_story_manifest_id CHAR(12),
	current_lives_inventory INT,
	total_story_nodes_completed INT,
	total_lives_spent INT,
	first_session_start_time CHAR(33),
	current_story_episode_number INT,
	current_coin_inventory INT,
	chill_id CHAR(32),
	total_stars_spent INT,
	current_ab_test VARCHAR(40),
	total_coins_spent INT,
	total_m3_level_losses INT,
	total_m3_level_attempts INT,
	current_story_episode_analytics_id VARCHAR(50),
	current_m3_level_number INT,
	previous_session_start_time CHAR(33),
	is_first_session INT,
	current_story_node_analytics_id VARCHAR(50),
	current_m3_level_id CHAR(12),
	current_star_inventory INT,
	current_story_node_id CHAR(12),
	total_revives_completed INT,
	current_story_segment_analytics_id VARCHAR(50),
	total_days_played INT,
	current_session_start_time CHAR(33),
	install_date CHAR(33),
	current_gem_inventory INT,
	total_story_segments_completed INT,
	current_story_episode_id CHAR(10),
	total_story_episodes_completed INT,
	current_m3_puzzle_id CHAR(12),
	total_m3_level_wins INT,
	install_app_version VARCHAR(30),
	current_story_analytics_id VARCHAR(100),
	m3_manifest_id CHAR(12),
	current_dn INT,
	current_characters_count INT,
	primary key (id),
	foreign key (user_id) references users(user_id) on delete cascade,
	foreign key (event_id) references events(id) on delete cascade
);

create table appsflyer_properties(
	id int auto_increment not null,
	user_id char(36) not null,
	event_id int not null,
	appsflyer_install_time CHAR(23),
	appsflyer_platform VARCHAR(15),
	appsflyer_bundle_id CHAR(22),
	appsflyer_af_ad VARCHAR(100),
	appsflyer_af_ad_type VARCHAR(50),
	appsflyer_idfv CHAR(36),
	appsflyer_region CHAR(2),
	appsflyer_install_time_selected_timezone CHAR(28),
	appsflyer_postal_code VARCHAR(30),
	appsflyer_appsflyer_id CHAR(21),
	appsflyer_af_c_id CHAR(17),
	appsflyer_device_download_time_selected_timezone CHAR(28),
	appsflyer_dma VARCHAR(30),
	appsflyer_event_time_selected_timezone CHAR(28),
	appsflyer_attributed_touch_type CHAR(5),
	appsflyer_api_version CHAR(3),
	appsflyer_selected_timezone CHAR(19),
	appsflyer_campaign VARCHAR(100),
	appsflyer_attributed_touch_time_selected_timezone CHAR(28),
	appsflyer_idfa CHAR(36),
	appsflyer_media_source VARCHAR(30),
	appsflyer_af_adset_id CHAR(17),
	appsflyer_country_code CHAR(2),
	appsflyer_af_channel VARCHAR(40),
	appsflyer_device_category CHAR(5),
	appsflyer_network_account_id CHAR(15),
	appsflyer_event_name CHAR(7),
	appsflyer_age_range CHAR(3),
	appsflyer_af_attribution_lookback CHAR(3),
	appsflyer_marketing_goal CHAR(12),
	appsflyer_event_source CHAR(3),
	appsflyer_campaign_start_date VARCHAR(30),
	appsflyer_campaign_title VARCHAR(40),
	appsflyer_gender VARCHAR(25),
	appsflyer_customer_user_id CHAR(36),
	appsflyer_event_time CHAR(23),
	appsflyer_attributed_touch_time CHAR(23),
	appsflyer_language CHAR(5),
	appsflyer_os_version VARCHAR(30),
	appsflyer_user_agent VARCHAR(100),
	appsflyer_sdk_version CHAR(7),
	appsflyer_app_name CHAR(12),
	appsflyer_app_id CHAR(12),
	appsflyer_marketing_objective CHAR(13),
	appsflyer_state VARCHAR(20),
	appsflyer_match_type CHAR(3),
	appsflyer_targeting_1 VARCHAR(30),
	appsflyer_wifi INT,
	appsflyer_city VARCHAR(50),
	appsflyer_af_adset VARCHAR(50),
	appsflyer_device_type VARCHAR(40),
	appsflyer_af_ad_id CHAR(30),
	appsflyer_is_retargeting INT,
	appsflyer_ip VARCHAR(25),
	appsflyer_selected_currency CHAR(3),
	appsflyer_device_download_time CHAR(23),
	appsflyer_app_version VARCHAR(25),
	primary key (id),
	foreign key (user_id) references users(user_id) on delete cascade,
	foreign key (event_id) references events(id) on delete cascade
);

create table event_properties(
	id int auto_increment not null,
	user_id char(36) not null,
	event_id int not null,
	attempt_count INT,
	points_overall_target INT,
	coming_from_id CHAR(12),
	total_session_count INT,
	coming_from VARCHAR(30),
	shuffle_count INT,
	m3_level_number INT,
	current_dn INT,
	characters_used_count INT,
	character_1_used_id CHAR(10),
	goals_count_remaining INT,
	loss_count INT,
	stars_won INT,
	is_first_session INT,
	m3_level_id CHAR(12),
	is_near_win INT,
	character_1_used_freq INT,
	character_2_used_freq INT,
	has_tutorial INT,
	m3_manifest_id CHAR(12),
	points_has_goals INT,
	total_days_played INT,
	m3_puzzle_id CHAR(12),
	m3_puzzle_version INT,
	moves_left INT,
	character_2_used VARCHAR(50),
	lives_used_count INT,
	m3_level_result VARCHAR(20),
	more_moves_count INT,
	character_1_used VARCHAR(50),
	character_2_used_id CHAR(10),
	character_rarity VARCHAR(30),
	character_id VARCHAR(30),
	revive_coin_cost INT,
	revive_advert_placement CHAR(20),
	revive_method VARCHAR(30),
	advert_trigger CHAR(16),
	advert_type CHAR(8),
	advert_placement CHAR(20),
	goals_progress_threshold INT,
	goals_progress INT,
	story_node_id CHAR(12),
	story_node_analytics_id VARCHAR(50),
	node_pause_count INT,
	story_segment_analytics_id VARCHAR(50),
	story_episode_number INT,
	story_episode_id CHAR(10),
	node_unpause_count INT,
	story_manifest_id CHAR(12),
	story_segment_id CHAR(12),
	story_analytics_id VARCHAR(100),
	node_type VARCHAR(40),
	node_skip_forwards_count INT,
	node_skip_backwards_count INT,
	coins_collected INT,
	choice CHAR(5),
	current_star_inventory INT,
	stars_required INT,
	start_state VARCHAR(30),
	action_taken_number INT,
	stars_consumed INT,
	total_options INT,
	enough_stars INT,
	action_taken_id VARCHAR(40),
	action_taken_type VARCHAR(50),
	character_3_used VARCHAR(50),
	character_3_used_id CHAR(10),
	character_3_used_freq INT,
	is_level_retry INT,
	total_revives_completed INT,
	step_type VARCHAR(50),
	action_taken_analytics_id VARCHAR(50),
	story_episode_analytics_id VARCHAR(50),
	points_score INT,
	points_overall_target_achieved INT,
	is_first_launch INT,
	loading_type VARCHAR(30),
	node_duration INT,
	is_showing_stars INT,
	loading_state CHAR(9),
	node_current_time INT,
	star_cost INT,
	loading_type_id CHAR(12),
	gems_awarded INT,
	coins_awarded INT,
	gem_cost INT,
	current_gem_inventory INT,
	can_afford INT,
	current_characters_count INT,
	source CHAR(5),
	is_first_character INT,
	is_duplicate INT,
	state CHAR(6),
	advert_error CHAR(15),
	revive_error VARCHAR(50),
	current_coin_inventory INT,
	product_id CHAR(35),
	purchase_error CHAR(13),
	item_id CHAR(10),
	coins_spent INT,
	is_correct INT,
	first_session_start_time CHAR(33),
	previous_session_start_time CHAR(33),
	current_session_start_time CHAR(33),
	primary key (id),
	foreign key (user_id) references users(user_id) on delete cascade,
	foreign key (event_id) references events(id) on delete cascade
);

-- Junction Tables
create table UserRetention(
    user_id char(36) not null,
    retention_id int not null,
    primary key (user_id, retention_id),
	foreign key (user_id) references users(user_id) on delete cascade,
	foreign key (retention_id) references retention(id) on delete cascade
);

create table UserTests(
    user_id char(36) not null,
    ab_id int not null,
    primary key (user_id, ab_id),
	foreign key (user_id) references users(user_id) on delete cascade,
	foreign key (ab_id) references ab_tests(id) on delete cascade
);


-- ADD FOREIGN KEYS TO USERS
alter table users
add foreign key (location_id)
references locations(id)
on delete cascade;

alter table users
add foreign key (gender_id)
references genders(id)
on delete cascade;

alter table users
add foreign key (device_id)
references devices(id)
on delete cascade;

alter table users
add foreign key (retention_id)
references retention(id)
on delete cascade;

alter table users
add foreign key (ab_test_id)
references ab_tests(id)
on delete cascade;
