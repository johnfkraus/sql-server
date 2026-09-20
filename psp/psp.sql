-- Create base tables
CREATE TABLE dbo.companies (
    company_id INT IDENTITY(1,1) PRIMARY KEY,
    company_name NVARCHAR(100) NOT NULL,
    headquarters NVARCHAR(100) NOT NULL
);

CREATE TABLE dbo.countries (
    country_id INT PRIMARY KEY,
    country_name NVARCHAR(100) NOT NULL,
    country_code CHAR(2) NOT NULL
);

CREATE TABLE dbo.companies_countries (
    company_id INT NOT NULL,
    country_id INT NOT NULL,
    PRIMARY KEY (company_id, country_id),
    FOREIGN KEY (company_id) REFERENCES dbo.companies(company_id),
    FOREIGN KEY (country_id) REFERENCES dbo.countries(country_id)
);

CREATE TABLE dbo.sectors (
    sector_id INT PRIMARY KEY,
    sector_name NVARCHAR(100) NOT NULL
);

CREATE TABLE dbo.companies_sectors (
    company_id INT NOT NULL,
    sector_id INT NOT NULL,
    PRIMARY KEY (company_id, sector_id),
    FOREIGN KEY (company_id) REFERENCES dbo.companies(company_id),
    FOREIGN KEY (sector_id) REFERENCES dbo.sectors(sector_id)
);

-- Seed Sectors & Countries
INSERT INTO dbo.sectors (sector_id, sector_name) VALUES 
(1, 'Technology'), (2, 'Healthcare'), (3, 'Finance'), (4, 'Energy');

INSERT INTO dbo.countries (country_id, country_name, country_code) VALUES 
(1, 'United States', 'US'), (2, 'France', 'FR'), (3, 'Germany', 'DE');

-- Seed Sample Companies
INSERT INTO dbo.companies (company_name, headquarters) VALUES
('Acme Tech', 'San Francisco'),
('BioHealth Labs', 'Paris'),
('Capital Finance', 'Frankfurt'),
('Delta Energy', 'Houston'),
('Echo Software', 'Seattle');

-- Map Companies to Sectors
INSERT INTO dbo.companies_sectors (company_id, sector_id) VALUES
(1, 1), -- Acme Tech -> Tech
(2, 2), -- BioHealth -> Healthcare
(3, 3), -- Capital -> Finance
(4, 4), -- Delta -> Energy
(5, 1); -- Echo -> Tech

-- Map Companies to Countries
INSERT INTO dbo.companies_countries (company_id, country_id) VALUES
(1, 1), (1, 2), (2, 2), (3, 3), (4, 1), (5, 1);