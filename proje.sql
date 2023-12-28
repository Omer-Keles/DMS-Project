-- Kisi Tablosu
CREATE TABLE Kisi (
    kisiID SERIAL,
    ad VARCHAR(50) NOT NULL ,
    soyad VARCHAR(50) NOT NULL ,
    yas INTEGER NOT NULL ,
    kisiTipi CHARACTER(1) NOT NULL,
    CONSTRAINT kisiPK PRIMARY KEY (kisiID)
);

-- Ulke Tablosu
CREATE TABLE Ulke (
    ulkeID SERIAL PRIMARY KEY,
    ulkeAd VARCHAR(50)
);

-- Lig Tablosu
CREATE TABLE Lig (
    ligID SERIAL PRIMARY KEY,
    ligAd VARCHAR(50),
    ulkeID INTEGER REFERENCES Ulke(ulkeID)
);

-- Kulup Tablosu
CREATE TABLE Kulup (
    kulupID SERIAL PRIMARY KEY,
    kulupAd VARCHAR(50),
    kupaSayi INTEGER,
    ligID INTEGER REFERENCES Lig(ligID)
);

-- MilliTakim Tablosu
CREATE TABLE MilliTakim (
    takimID SERIAL PRIMARY KEY,
    milliAd VARCHAR(50),
    kupaSayi INTEGER
);

-- Futbolcu Tablosu
CREATE TABLE Futbolcu (
    kisiID INT,
    mevki VARCHAR(50),
    kulupID INTEGER REFERENCES Kulup(kulupID),
    milliID INTEGER REFERENCES MilliTakim(takimID),
    CONSTRAINT futbolcuPK PRIMARY KEY (kisiID)
);

-- TeknikDirektor Tablosu
CREATE TABLE TeknikDirektor (
    kisiID INT,
    kulupID INTEGER REFERENCES Kulup(kulupID),
    milliID INTEGER REFERENCES MilliTakim(takimID),
    CONSTRAINT teknikdirektorPK PRIMARY KEY (kisiID)
);

-- Hakem Tablosu
CREATE TABLE Hakem (
    kisiID INT,
    CONSTRAINT hakemPK PRIMARY KEY (kisiID)
);

ALTER TABLE Futbolcu
    ADD CONSTRAINT FutbolcuKisi FOREIGN KEY (kisiID)
    REFERENCES Kisi (kisiID)
    ON DELETE CASCADE
    ON UPDATE CASCADE;

ALTER  TABLE TeknikDirektor
    ADD CONSTRAINT  TeknikDirektorKisi FOREIGN KEY (kisiID)
    REFERENCES Kisi (kisiID)
    ON DELETE CASCADE
    ON UPDATE CASCADE;

ALTER TABLE Hakem
    ADD CONSTRAINT HakemKisi FOREIGN KEY (kisiID)
    REFERENCES  Kisi (kisiID)
    ON DELETE CASCADE
    ON UPDATE CASCADE;

-- Il Tablosu
CREATE TABLE Il (
    ilID SERIAL PRIMARY KEY,
    ulkeID INTEGER REFERENCES Ulke(ulkeID),
    ilAd VARCHAR(50)
);

-- StatBilgi Tablosu
CREATE TABLE StatBilgi (
    statID SERIAL PRIMARY KEY,
    kulupID INTEGER REFERENCES Kulup(kulupID),
    ilID INTEGER REFERENCES Il(ilID),
    statAd VARCHAR(50)
);

-- Mac Tablosu
CREATE TABLE Mac (
    macID SERIAL PRIMARY KEY,
    ligID INTEGER REFERENCES Lig(ligID),
    evID INTEGER REFERENCES Kulup(kulupID),
    depID INTEGER REFERENCES Kulup(kulupID),
    skorEv INTEGER,
    skorDep INTEGER
);

-- MacHakem Tablosu
CREATE TABLE MacHakem (
    macHakemID SERIAL PRIMARY KEY,
    macID INTEGER REFERENCES Mac(macID),
    hakemID INTEGER REFERENCES Hakem(kisiID)
);

-- KulupMac Tablosu
CREATE TABLE KulupMac (
    kulupMacID SERIAL PRIMARY KEY,
    kulupID INTEGER REFERENCES Kulup(kulupID),
    macID INTEGER REFERENCES Mac(macID)
);

-- FutbolcuIstatistik Tablosu
CREATE TABLE FutbolcuIstatistik (
    istatistikID SERIAL PRIMARY KEY,
    futbolcuID INTEGER REFERENCES Futbolcu(kisiID),
    macSayisi INTEGER,
    gol INTEGER,
    asist INTEGER
);

-- TdIstatistik Tablosu
CREATE TABLE TdIstatistik (
    istatistikID SERIAL PRIMARY KEY,
    tdID INTEGER REFERENCES TeknikDirektor(kisiID),
    macSayi INTEGER,
    galibiyet INTEGER,
    beraber INTEGER,
    maglubiyet INTEGER
);

--Fonksiyonlar

CREATE OR REPLACE FUNCTION futbolcuAra(futbolcuAd VARCHAR(40))
RETURNS TABLE(adi VARCHAR(40), soyadi VARCHAR(40), yasi INT, kulupAdi VARCHAR(50), milliTakimi VARCHAR(50), mevkisi VARCHAR(50), maci INT, golu INT, asisti INT)
AS
    $$
    BEGIN
        RETURN QUERY
        SELECT ad, soyad, yas, kulupad, milliad, mevki, macsayisi, gol, asist
        FROM kisi
        INNER JOIN futbolcu ON kisi.kisiID = futbolcu.kisiID
        INNER JOIN futbolcuistatistik ON futbolcu.kisiID = futbolcuistatistik.futbolcuID
        INNER JOIN millitakim ON futbolcu.milliID = millitakim.takimID
        INNER JOIN kulup ON futbolcu.kulupID = kulup.kulupID
        WHERE kisiTipi = 'F' AND ad = futbolcuAd;
    END;
    $$
language "plpgsql";

CREATE OR REPLACE FUNCTION ligAra(ligAdi VARCHAR(40))
RETURNS TABLE(takimAdi VARCHAR(40), macSayisi INT, galibiyetSayi INT, beraberlikSayi INT, maglubiyetSayi INT, toplamPuani INT)
AS
    $$
    BEGIN
        RETURN QUERY
        SELECT kulupAd, macsayi, galibiyet, beraber, maglubiyet, (galibiyet * 3 + beraber) AS toplamPuan
        FROM kulup
        INNER JOIN teknikdirektor ON kulup.kulupID = teknikdirektor.kulupID
        INNER JOIN tdistatistik ON teknikdirektor.kisiID = tdistatistik.tdID
        INNER JOIN lig ON kulup.ligID = lig.ligID
        WHERE Lig.ligAd = ligAdi
        ORDER BY toplamPuan DESC;
    END;
    $$
language "plpgsql";

CREATE  OR REPLACE FUNCTION macAra(ligAdi VARCHAR(40))
RETURNS TABLE(evTakimi VARCHAR(40), evSkor INT, depSkor INT, depTakimi VARCHAR(40), hakemAd VARCHAR(40), hakemSoyad VARCHAR(40))
AS
    $$
    BEGIN
        RETURN QUERY
        SELECT k1.kulupad, skorev, skordep, k2.kulupad, ad, soyad
        FROM mac
        INNER JOIN kulup k1 ON k1.kulupid = mac.evid
        INNER JOIN kulup k2 ON k2.kulupid = mac.depid
        INNER JOIN machakem ON mac.macid = machakem.macid
        INNER JOIN kisi ON kisi.kisiid = machakem.hakemid
        INNER JOIN lig ON mac.ligID = lig.ligID
        WHERE Lig.ligAd = ligAdi;
    END;
    $$
language "plpgsql";

CREATE OR REPLACE FUNCTION takimAra(takimAdi VARCHAR(40))
RETURNS TABLE(takim VARCHAR(40), ulkeAdi VARCHAR(40), ilAdi VARCHAR(40), statAdi VARCHAR(40),kupaSayisi INT, tdAdi VARCHAR(40), tdSoyadi VARCHAR(40))
AS
    $$
    BEGIN
        RETURN QUERY
        SELECT kulupad, ulkeAd, ilAd, statAd, kupaSayi,ad, soyad
        FROM kulup
        INNER JOIN statbilgi ON kulup.kulupID = statbilgi.kulupID
        INNER JOIN il ON statbilgi.ilID = il.ilID
        INNER JOIN ulke ON il.ulkeID = ulke.ulkeID
        INNER JOIN teknikdirektor ON kulup.kulupID = teknikdirektor.kulupID
        INNER JOIN kisi ON kisi.kisiID = TeknikDirektor.kisiID
        WHERE Kulup.kulupAd = takimAdi;
    END;
    $$
language "plpgsql";

CREATE OR REPLACE FUNCTION kulupIdDondur(v_kulupad VARCHAR)
RETURNS INTEGER AS
    $$
    DECLARE
    v_kulupID INT;
    BEGIN
        SELECT kulupID INTO v_kulupID
        FROM Kulup
        WHERE kulupAd= v_kulupad;
        RETURN v_kulupID;
    END;
    $$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION milliIdDondur(v_milliad VARCHAR)
RETURNS INTEGER AS
    $$
    DECLARE
    v_milliID INT;
    BEGIN
        SELECT takimID INTO v_milliID
        FROM millitakim
        WHERE milliad = v_milliad;
        RETURN v_milliID;
    END;
    $$
LANGUAGE plpgsql;

--Trigger

CREATE OR REPLACE FUNCTION kisiEkleTR()
RETURNS TRIGGER
AS
$$
BEGIN
    NEW.ad = TRIM(NEW.ad); -- büyük harfe dönüştürdükten sonra ekle
    NEW.soyad = TRIM(NEW."soyad"); -- Önceki ve sonraki boşlukları temizle
    NEW.yas = NEW.yas;
    NEW.kisitipi = TRIM(NEW.kisitipi);
    IF NEW.ad IS NULL OR NEW.soyad IS NULL OR NEW.kisiTipi IS NULL THEN
            RAISE EXCEPTION 'Boş alan olamaz!';
    END IF;
    RETURN NEW;
END;
$$
LANGUAGE "plpgsql";

CREATE TRIGGER kisiKontrol
BEFORE INSERT OR UPDATE ON kisi
FOR EACH ROW
EXECUTE PROCEDURE kisiEkleTR();

CREATE OR REPLACE FUNCTION futbolcuEkleTR()
RETURNS TRIGGER
AS
    $$
    BEGIN
        NEW.mevki = TRIM(NEW.mevki);
        IF NEW.mevki IS NULL THEN
            RAISE EXCEPTION 'Boş alan olamaz!';
        END IF;
        RETURN NEW;
    END;
    $$
LANGUAGE "plpgsql";

CREATE TRIGGER futbolcuKontrol
BEFORE INSERT OR UPDATE ON futbolcu
FOR EACH ROW
EXECUTE PROCEDURE futbolcuEkleTR();

CREATE OR REPLACE FUNCTION istatistikEkleTR()
RETURNS TRIGGER
AS
    $$
    BEGIN
        NEW.macsayisi = NEW.macsayisi;
        NEW.gol = NEW.gol;
        NEW.asist = NEW.asist;
        IF NEW.macsayisi < 0 OR NEW.gol < 0 OR NEW.asist < 0 THEN
            RAISE EXCEPTION 'istatistikler negatif olamaz';
        END IF;
        RETURN NEW;
    END;
    $$
LANGUAGE "plpgsql";

CREATE TRIGGER istatistikKontrol
BEFORE INSERT OR UPDATE ON futbolcuistatistik
FOR EACH ROW
EXECUTE PROCEDURE istatistikEkleTR();

CREATE TABLE transferler
(
    trasnferNo SERIAL,
    eskiKulup SMALLINT,
    yeniKulup SMALLINT,
    CONSTRAINT PK PRIMARY KEY (trasnferNo)
);
CREATE OR REPLACE FUNCTION transferTR()
RETURNS TRIGGER
AS
$$
BEGIN
    IF NEW.kulupid <> OLD.kulupid THEN
        INSERT INTO transferler (eskiKulup, yeniKulup)  VALUES(OLD.kulupid,NEW.kulupid);
    END IF;
RETURN NEW;
END;
$$
LANGUAGE "plpgsql";

CREATE TRIGGER transferKontrol
BEFORE UPDATE ON futbolcu
FOR EACH ROW
EXECUTE PROCEDURE transferTR();

INSERT INTO ulke (ulkeid, ulkead) VALUES
(1, 'Türkiye');

INSERT INTO Lig (ligAd, ulkeID) VALUES
('Türkiye Süper Lig', 1);

INSERT INTO kulup (kulupAd, kupaSayi, ligID) VALUES
('Fenerbahçe', 18, 1), --1
('Galatasaray', 23, 1), --2
('Beşiktaş', 16, 1), --3
('Trabzonspor', 8, 1), --4
('Kayserispor', 0, 1), --5
('Adana Demirspor', 0, 1), --6
('Antalyaspor', 0, 1), --7
('Rizespor', 0, 1), --8
('Kasımpaşa', 0, 1), --9
('Hatayspor', 0, 1), --10
('Ankaragücü', 0, 1), --11
('Başakşehir', 1, 1), --12
('Sivasspor', 0, 1), --13
('Karagümrük', 0, 1), --14
('Gaziantep', 0, 1), --15
('Konyaspor', 0, 1), --16
('Samsunspor', 0, 1), --17
('Alanyaspor', 0, 1), --18
('Pendikspor', 0, 1), --19
('İstanbulspor', 0, 1); --20

INSERT INTO il (ulkeID, ilAd) VALUES
(1, 'İstanbul'),
(1, 'Trabzon'),
(1, 'Kayseri'),
(1, 'Adana'),
(1, 'Antalya'),
(1, 'Rize'),
(1, 'Hatay'),
(1, 'Ankara'),
(1, 'Sivas'),
(1, 'Gaziantep'),
(1, 'Konya'),
(1, 'Samsun');


INSERT INTO MilliTakim (milliAd, kupaSayi) VALUES
('Türkiye', 0), --1
('Hırvatistan', 0), --2
('Nijerya', 0), --3
('Gana', 0), --4
('Brezilya', 5), --5
('Polonya', 0), --6
('Sırbistan', 0), --7
('Belçika', 0), --8
('Uruguay', 2), --9
('Kolombiya', 0), --10
('Fransa', 2), --11
('Almanya', 4), --12
('Fas', 0), --13
('Arjantin', 3), --14
('Fildişi Sahili', 0), --15
('Demokratik Kongo', 0), --16
('İngiltere', 1), --17
('Portekiz', 0), --18
('Danimarka', 0), --19
('Surinam', 0), --20
('Bosna-Hersek', 0), --21
('Yunanistan', 0), --22
('Mısır', 0), --23
('Gürcistan', 0), --24
('Romanya', 0); --25

INSERT INTO statbilgi (kulupID, ilID, statAd) VALUES
(1, 1, 'Ülker Stadyumu'),
(2, 1, 'Rams Park'),
(3, 1, 'Tüpraş Stadyumu'),
(4, 2, 'Papara Park'),
(5, 3, 'RHG Enertürk Enerji Stadyumu'),
(6, 4, 'Yeni Adana Stadyumu'),
(7, 5, 'Corendon Airlines Park'),
(8, 6, 'Çaykur Didi Stadyumu'),
(9, 1, 'Recep Tayyip Erdoğan Stadyumu'),
(10, 7, 'Yeni Hatay Stadyumu'),
(11, 8,'Eryaman Stadyumu'),
(12, 1, 'Başakşehir Fatih Terim Stadyumu'),
(13, 9, 'BG Group 4 Eylül Stadyumu'),
(14, 1, 'Atatürk Olimpiyat Stadı'),
(15, 10, 'Kalyon Stadyumu'),
(16, 11, 'Konya Büyükşehir Belediye Stadyumu'),
(17, 12, 'Samsun Yeni 19 Mayıs Stadyumu'),
(18, 5, 'Kırbıyık Holding Stadyumu'),
(19, 1, 'Siltaş Yapı Pendik Stadyumu'),
(20, 1, 'Necmi Kadıoğlu Stadyumu');


--Fenerbahçe TD ve oyuncular
INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('İsmail', 'Kartal', 62, 'T');
INSERT INTO TeknikDirektor (kisiID, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 1, 1);
INSERT INTO TdIstatistik (tdID, macSayi, galibiyet, beraber, maglubiyet)
VALUES (currval('kisi_kisiid_seq'), 16, 14, 1, 1);

INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Dominik', 'Livakovic', 28, 'F');
INSERT INTO Futbolcu (kisiID, mevki, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 'Kaleci', 1, 2);
INSERT INTO futbolcuistatistik (futbolcuID, macSayisi, gol, asist)
VALUES (currval('kisi_kisiid_seq'), 13, 0, 0);


INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Bright', 'Osayi-Samuel', 25, 'F');
INSERT INTO Futbolcu (kisiID, mevki, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 'Defans', 1, 3);
INSERT INTO futbolcuistatistik (futbolcuID, macSayisi, gol, asist)
VALUES (currval('kisi_kisiid_seq'), 12, 2, 1);

INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Serdar', 'Aziz', 33, 'F');
INSERT INTO Futbolcu (kisiID, mevki, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 'Defans', 1, 1);
INSERT INTO futbolcuistatistik (futbolcuID, macSayisi, gol, asist)
VALUES (currval('kisi_kisiid_seq'), 4, 0, 0);

INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Alexander', 'Djiku', 29, 'F');
INSERT INTO Futbolcu (kisiID, mevki, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 'Defans', 1, 4);
INSERT INTO futbolcuistatistik (futbolcuID, macSayisi, gol, asist)
VALUES (currval('kisi_kisiid_seq'), 10, 1, 0);

INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Ferdi', 'Kadıoğlu', 24, 'F');
INSERT INTO Futbolcu (kisiID, mevki, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 'Orta Saha', 1, 1);
INSERT INTO futbolcuistatistik (futbolcuID, macSayisi, gol, asist)
VALUES (currval('kisi_kisiid_seq'), 15, 0, 2);

INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('İsmail', 'Yüksek', 24, 'F');
INSERT INTO Futbolcu (kisiID, mevki, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 'Orta Saha', 1, 1);
INSERT INTO futbolcuistatistik (futbolcuID, macSayisi, gol, asist)
VALUES (currval('kisi_kisiid_seq'), 14, 0, 1);

INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Fredico', 'Santos', 30, 'F');
INSERT INTO Futbolcu (kisiID, mevki, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 'Orta Saha', 1, 5);
INSERT INTO futbolcuistatistik (futbolcuID, macSayisi, gol, asist)
VALUES (currval('kisi_kisiid_seq'), 11, 0, 1);

INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Cengiz', 'Ünder', 26, 'F');
INSERT INTO Futbolcu (kisiID, mevki, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 'Forvet', 1, 1);
INSERT INTO futbolcuistatistik (futbolcuID, macSayisi, gol, asist)
VALUES (currval('kisi_kisiid_seq'), 7, 0, 1);

INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Sebastian', 'Szymanski', 24, 'F');
INSERT INTO Futbolcu (kisiID, mevki, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 'Orta Saha', 1, 6);
INSERT INTO futbolcuistatistik (futbolcuID, macSayisi, gol, asist)
VALUES (currval('kisi_kisiid_seq'), 16, 8, 4);

INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Dusan', 'Tadic', 35, 'F');
INSERT INTO Futbolcu (kisiID, mevki, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 'Forvet', 1, 7);
INSERT INTO futbolcuistatistik (futbolcuID, macSayisi, gol, asist)
VALUES (currval('kisi_kisiid_seq'), 16, 7, 6);

INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Michy', 'Batshuayi', 30, 'F');
INSERT INTO Futbolcu (kisiID, mevki, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 'Forvet', 1, 8);
INSERT INTO futbolcuistatistik (futbolcuID, macSayisi, gol, asist)
VALUES (currval('kisi_kisiid_seq'), 8, 0, 1);


--Galatasaray TD ve futbolcular


INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Okan', 'Buruk', 50, 'T');
INSERT INTO TeknikDirektor (kisiID, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 2, 1);
INSERT INTO TdIstatistik (tdID, macSayi, galibiyet, beraber, maglubiyet)
VALUES (currval('kisi_kisiid_seq'), 16, 14, 1, 1);

INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Fernando', 'Muslera', 37, 'F');
INSERT INTO Futbolcu (kisiID, mevki, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 'Kaleci', 2, 9);
INSERT INTO futbolcuistatistik (futbolcuID, macSayisi, gol, asist)
VALUES (currval('kisi_kisiid_seq'), 15, 0, 0);

INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Davinson', 'Sanchez', 27, 'F');
INSERT INTO Futbolcu (kisiID, mevki, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 'Defans', 2, 10);
INSERT INTO futbolcuistatistik (futbolcuID, macSayisi, gol, asist)
VALUES (currval('kisi_kisiid_seq'), 8, 1, 0);

INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Sacha', 'Boey', 23, 'F');
INSERT INTO Futbolcu (kisiID, mevki, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 'Defans', 2, 11);
INSERT INTO futbolcuistatistik (futbolcuID, macSayisi, gol, asist)
VALUES (currval('kisi_kisiid_seq'), 15, 1, 0);

INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Abdülkerim', 'Bardakçı', 29, 'F');
INSERT INTO Futbolcu (kisiID, mevki, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 'Defans', 2, 1);
INSERT INTO futbolcuistatistik (futbolcuID, macSayisi, gol, asist)
VALUES (currval('kisi_kisiid_seq'), 13, 1, 0);

INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Barış Alper', 'Yılmaz', 23, 'F');
INSERT INTO Futbolcu (kisiID, mevki, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 'Forvet', 2, 1);
INSERT INTO futbolcuistatistik (futbolcuID, macSayisi, gol, asist)
VALUES (currval('kisi_kisiid_seq'), 16, 0, 0);

INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Kerem', 'Demirbay', 30, 'F');
INSERT INTO Futbolcu (kisiID, mevki, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 'Orta Saha', 2, 12);
INSERT INTO futbolcuistatistik (futbolcuID, macSayisi, gol, asist)
VALUES (currval('kisi_kisiid_seq'), 13, 0, 0);

INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Lucas', 'Torreira', 27, 'F');
INSERT INTO Futbolcu (kisiID, mevki, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 'Orta Saha', 2, 9);
INSERT INTO futbolcuistatistik (futbolcuID, macSayisi, gol, asist)
VALUES (currval('kisi_kisiid_seq'), 15, 1, 0);

INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Hakim', 'Ziyech', 30, 'F');
INSERT INTO Futbolcu (kisiID, mevki, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 'Orta Saha', 2, 13);
INSERT INTO futbolcuistatistik (futbolcuID, macSayisi, gol, asist)
VALUES (currval('kisi_kisiid_seq'), 8, 2, 1);

INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Dries', 'Mertens', 36, 'F');
INSERT INTO Futbolcu (kisiID, mevki, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 'Forvet', 2, 8);
INSERT INTO futbolcuistatistik (futbolcuID, macSayisi, gol, asist)
VALUES (currval('kisi_kisiid_seq'), 14, 2, 3);

INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Kerem', 'Aktürkoğlu', 25, 'F');
INSERT INTO Futbolcu (kisiID, mevki, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 'Forvet', 2, 1);
INSERT INTO futbolcuistatistik (futbolcuID, macSayisi, gol, asist)
VALUES (currval('kisi_kisiid_seq'), 16, 5, 5);

INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Mauro', 'İcardi', 30, 'F');
INSERT INTO Futbolcu (kisiID, mevki, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 'Forvet', 2, 14);
INSERT INTO futbolcuistatistik (futbolcuID, macSayisi, gol, asist)
VALUES (currval('kisi_kisiid_seq'), 16, 12, 5);


--Beşiktaş takımı


INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Rıza', 'Çalımbay', 60, 'T');
INSERT INTO TeknikDirektor (kisiID, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 3, 1);
INSERT INTO TdIstatistik (tdID, macSayi, galibiyet, beraber, maglubiyet)
VALUES (currval('kisi_kisiid_seq'), 16, 8, 2, 6);

INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Mert', 'Günok', 34, 'F');
INSERT INTO Futbolcu (kisiID, mevki, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 'Kaleci', 3, 1);
INSERT INTO futbolcuistatistik (futbolcuID, macSayisi, gol, asist)
VALUES (currval('kisi_kisiid_seq'), 11, 0, 0);

INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Onur', 'Bulut', 29, 'F');
INSERT INTO Futbolcu (kisiID, mevki, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 'Defans', 3, 1);
INSERT INTO futbolcuistatistik (futbolcuID, macSayisi, gol, asist)
VALUES (currval('kisi_kisiid_seq'), 14, 0, 1);

INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Eric', 'Baily', 29, 'F');
INSERT INTO Futbolcu (kisiID, mevki, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 'Defans', 3, 15);
INSERT INTO futbolcuistatistik (futbolcuID, macSayisi, gol, asist)
VALUES (currval('kisi_kisiid_seq'), 5, 0, 0);

INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Daniel', 'Amartey', 29, 'F');
INSERT INTO Futbolcu (kisiID, mevki, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 'Defans', 3, 4);
INSERT INTO futbolcuistatistik (futbolcuID, macSayisi, gol, asist)
VALUES (currval('kisi_kisiid_seq'), 8, 0, 0);

INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Umut', 'Meraş', 28, 'F');
INSERT INTO Futbolcu (kisiID, mevki, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 'Defans', 3, 1);
INSERT INTO futbolcuistatistik (futbolcuID, macSayisi, gol, asist)
VALUES (currval('kisi_kisiid_seq'), 2, 0, 0);

INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Necip', 'Uysal', 32, 'F');
INSERT INTO Futbolcu (kisiID, mevki, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 'Defans', 3, 1);
INSERT INTO futbolcuistatistik (futbolcuID, macSayisi, gol, asist)
VALUES (currval('kisi_kisiid_seq'), 12, 0, 1);

INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Alexander', 'Oxlade-Chamberlain', 30, 'F');
INSERT INTO Futbolcu (kisiID, mevki, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 'Orta Saha', 3, 17);
INSERT INTO futbolcuistatistik (futbolcuID, macSayisi, gol, asist)
VALUES (currval('kisi_kisiid_seq'), 13, 4, 1);

INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Gedson', 'Fernandes', 24, 'F');
INSERT INTO Futbolcu (kisiID, mevki, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 'Orta Saha', 3, 18);
INSERT INTO futbolcuistatistik (futbolcuID, macSayisi, gol, asist)
VALUES (currval('kisi_kisiid_seq'), 11, 1, 1);

INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Ante', 'Rebic', 30, 'F');
INSERT INTO Futbolcu (kisiID, mevki, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 'Forvet', 3, 2);
INSERT INTO futbolcuistatistik (futbolcuID, macSayisi, gol, asist)
VALUES (currval('kisi_kisiid_seq'), 9, 0, 2);

INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Cenk', 'Tosun', 32, 'F');
INSERT INTO Futbolcu (kisiID, mevki, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 'Forvet', 3, 1);
INSERT INTO futbolcuistatistik (futbolcuID, macSayisi, gol, asist)
VALUES (currval('kisi_kisiid_seq'), 12, 3, 1);


--Trabzon Takımı

INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Abdullah', 'Avcı', 60, 'T');
INSERT INTO TeknikDirektor (kisiID, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 4, 1);
INSERT INTO TdIstatistik (tdID, macSayi, galibiyet, beraber, maglubiyet)
VALUES (currval('kisi_kisiid_seq'), 16, 9, 2, 5);

INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Uğurcan', 'Çakır', 27, 'F');
INSERT INTO Futbolcu (kisiID, mevki, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 'Kaleci', 4, 1);
INSERT INTO futbolcuistatistik (futbolcuID, macSayisi, gol, asist)
VALUES (currval('kisi_kisiid_seq'), 16, 0, 0);

INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Jens', 'Larsen', 32, 'F');
INSERT INTO Futbolcu (kisiID, mevki, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 'Defans', 4, 19);
INSERT INTO futbolcuistatistik (futbolcuID, macSayisi, gol, asist)
VALUES (currval('kisi_kisiid_seq'), 13, 0, 0);

INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Batista', 'Mendy', 23, 'F');
INSERT INTO Futbolcu (kisiID, mevki, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 'Defans', 4, 11);
INSERT INTO futbolcuistatistik (futbolcuID, macSayisi, gol, asist)
VALUES (currval('kisi_kisiid_seq'), 10, 0, 0);

INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Stefano', 'Denswil', 30, 'F');
INSERT INTO Futbolcu (kisiID, mevki, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 'Defans', 4, 20);
INSERT INTO futbolcuistatistik (futbolcuID, macSayisi, gol, asist)
VALUES (currval('kisi_kisiid_seq'), 12, 1, 0);

INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Eren', 'Elmalı', 23, 'F');
INSERT INTO Futbolcu (kisiID, mevki, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 'Defans', 4, 1);
INSERT INTO futbolcuistatistik (futbolcuID, macSayisi, gol, asist)
VALUES (currval('kisi_kisiid_seq'), 14, 0, 0);

INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Berat', 'Özdemir', 25, 'F');
INSERT INTO Futbolcu (kisiID, mevki, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 'Orta Saha', 4, 1);
INSERT INTO futbolcuistatistik (futbolcuID, macSayisi, gol, asist)
VALUES (currval('kisi_kisiid_seq'), 11, 1, 0);

INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Edin', 'Visca', 33, 'F');
INSERT INTO Futbolcu (kisiID, mevki, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 'Orta Saha', 4, 21);
INSERT INTO futbolcuistatistik (futbolcuID, macSayisi, gol, asist)
VALUES (currval('kisi_kisiid_seq'), 15, 2, 3);

INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Abdülkadir', 'Ömür', 24, 'F');
INSERT INTO Futbolcu (kisiID, mevki, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 'Orta Saha', 4, 1);
INSERT INTO futbolcuistatistik (futbolcuID, macSayisi, gol, asist)
VALUES (currval('kisi_kisiid_seq'), 15, 0, 6);

INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Anastasios', 'Bakasetas', 30, 'F');
INSERT INTO Futbolcu (kisiID, mevki, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 'Orta Saha', 4, 22);
INSERT INTO futbolcuistatistik (futbolcuID, macSayisi, gol, asist)
VALUES (currval('kisi_kisiid_seq'), 14, 4, 1);

INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Mahmoud', 'Trezeguet', 29, 'F');
INSERT INTO Futbolcu (kisiID, mevki, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 'Orta Saha', 4, 23);
INSERT INTO futbolcuistatistik (futbolcuID, macSayisi, gol, asist)
VALUES (currval('kisi_kisiid_seq'), 12, 4, 2);

INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Ebere Paul', 'Onuachu', 29, 'F');
INSERT INTO Futbolcu (kisiID, mevki, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 'Forvet', 4, 3);
INSERT INTO futbolcuistatistik (futbolcuID, macSayisi, gol, asist)
VALUES (currval('kisi_kisiid_seq'), 12, 8, 1);


-- Kayseri Takımı


INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Recep', 'Uçar', 48, 'T');
INSERT INTO TeknikDirektor (kisiID, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 5, 1);
INSERT INTO TdIstatistik (tdID, macSayi, galibiyet, beraber, maglubiyet)
VALUES (currval('kisi_kisiid_seq'), 16, 8, 5, 3);


-- Adana Demirspor takımı


INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Serkan', 'Damla', 50, 'T');
INSERT INTO TeknikDirektor (kisiID, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 6, 1);
INSERT INTO TdIstatistik (tdID, macSayi, galibiyet, beraber, maglubiyet)
VALUES (currval('kisi_kisiid_seq'), 16, 6, 6, 4);


--Antalya Takımı


INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Nuri', 'Şahin', 35, 'T');
INSERT INTO TeknikDirektor (kisiID, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 7, 1);
INSERT INTO TdIstatistik (tdID, macSayi, galibiyet, beraber, maglubiyet)
VALUES (currval('kisi_kisiid_seq'), 16, 6, 6, 4);


--Rize Takımı


INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('İlhan', 'Palut', 47, 'T');
INSERT INTO TeknikDirektor (kisiID, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 8, 1);
INSERT INTO TdIstatistik (tdID, macSayi, galibiyet, beraber, maglubiyet)
VALUES (currval('kisi_kisiid_seq'), 16, 7, 4, 5);


-- Kasımpaşa


INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Sami', 'Uğurlu', 45, 'T');
INSERT INTO TeknikDirektor (kisiID, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 9, 1);
INSERT INTO TdIstatistik (tdID, macSayi, galibiyet, beraber, maglubiyet)
VALUES (currval('kisi_kisiid_seq'), 16, 6, 4, 6);


-- Hatay


INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Volkan', 'Demirel', 42, 'T');
INSERT INTO TeknikDirektor (kisiID, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 10, 1);
INSERT INTO TdIstatistik (tdID, macSayi, galibiyet, beraber, maglubiyet)
VALUES (currval('kisi_kisiid_seq'), 16, 4, 7, 5);


--Ankaragücü


INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Emre', 'Belözoğlu', 43, 'T');
INSERT INTO TeknikDirektor (kisiID, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 11, 1);
INSERT INTO TdIstatistik (tdID, macSayi, galibiyet, beraber, maglubiyet)
VALUES (currval('kisi_kisiid_seq'), 16, 4, 7, 5);


--Başakşehir


INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Mustafa', 'Keçeli', 45, 'T');
INSERT INTO TeknikDirektor (kisiID, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 12, 1);
INSERT INTO TdIstatistik (tdID, macSayi, galibiyet, beraber, maglubiyet)
VALUES (currval('kisi_kisiid_seq'), 16, 5, 3, 8);


--Sivas


INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Servet', 'Çetin', 42, 'T');
INSERT INTO TeknikDirektor (kisiID, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 13, 1);
INSERT INTO TdIstatistik (tdID, macSayi, galibiyet, beraber, maglubiyet)
VALUES (currval('kisi_kisiid_seq'), 16, 4, 6, 6);


--Fatih karagümrük


INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Shota', 'Arveladze', 50, 'T');
INSERT INTO TeknikDirektor (kisiID, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 14, 24);
INSERT INTO TdIstatistik (tdID, macSayi, galibiyet, beraber, maglubiyet)
VALUES (currval('kisi_kisiid_seq'), 16, 4, 5, 7);


--Gaziantep


INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Marius', 'Şumudica', 52, 'T');
INSERT INTO TeknikDirektor (kisiID, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 15, 25);
INSERT INTO TdIstatistik (tdID, macSayi, galibiyet, beraber, maglubiyet)
VALUES (currval('kisi_kisiid_seq'), 16, 5, 1, 10);


--Konya


INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Hakan', 'Keleş', 51, 'T');
INSERT INTO TeknikDirektor (kisiID, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 16, 1);
INSERT INTO TdIstatistik (tdID, macSayi, galibiyet, beraber, maglubiyet)
VALUES (currval('kisi_kisiid_seq'), 16, 3, 6, 7);


--Samsun


INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Markus', 'Gidsol', 54, 'T');
INSERT INTO TeknikDirektor (kisiID, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 17, 12);
INSERT INTO TdIstatistik (tdID, macSayi, galibiyet, beraber, maglubiyet)
VALUES (currval('kisi_kisiid_seq'), 16, 4, 3, 9);


-- Alanya


INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Fatih', 'Tekke', 46, 'T');
INSERT INTO TeknikDirektor (kisiID, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 18, 1);
INSERT INTO TdIstatistik (tdID, macSayi, galibiyet, beraber, maglubiyet)
VALUES (currval('kisi_kisiid_seq'), 16, 4, 5, 7);


--Pendik


INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Ivo', 'Vieira', 47, 'T');
INSERT INTO TeknikDirektor (kisiID, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 19, 18);
INSERT INTO TdIstatistik (tdID, macSayi, galibiyet, beraber, maglubiyet)
VALUES (currval('kisi_kisiid_seq'), 16, 3, 4, 9);


--İstanbul


INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Hakan', 'Yakın', 46, 'T');
INSERT INTO TeknikDirektor (kisiID, kulupID, milliID)
VALUES (currval('kisi_kisiid_seq'), 20, 1);
INSERT INTO TdIstatistik (tdID, macSayi, galibiyet, beraber, maglubiyet)
VALUES (currval('kisi_kisiid_seq'), 16, 2, 2, 12);


-- 17. haftanın maçlarını ve kulupMaclarını ekleme, Hakemleri Ekleme, MacHakemlerini ekleme


INSERT INTO mac (ligID, evID, depID, skorEv, skorDep)
VALUES (1, 12, 13, 3, 1); -- BFK SVS
INSERT INTO kulupmac (kulupID, macID)
VALUES (12, currval('mac_macid_seq'));
INSERT INTO kulupmac (kulupID, macID)
VALUES (13, currval('mac_macid_seq'));
INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Mete', 'Kalkavan', 50, 'H');
INSERT INTO Hakem (kisiID)
VALUES (currval('kisi_kisiid_seq'));
INSERT INTO machakem (macID, hakemID)
VALUES (currval('mac_macid_seq'), currval('kisi_kisiid_seq'));

INSERT INTO mac (ligID, evID, depID, skorEv, skorDep)
VALUES (1, 20, 4, 0, 3);
INSERT INTO kulupmac (kulupID, macID)
VALUES (20, currval('mac_macid_seq'));
INSERT INTO kulupmac (kulupID, macID)
VALUES (4, currval('mac_macid_seq'));
INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Ali', 'Şansalan', 50, 'H');
INSERT INTO Hakem (kisiID)
VALUES (currval('kisi_kisiid_seq'));
INSERT INTO machakem (macID, hakemID)
VALUES (currval('mac_macid_seq'), currval('kisi_kisiid_seq'));

INSERT INTO mac (ligID, evID, depID, skorEv, skorDep)
VALUES (1, 15, 6, 2, 2);
INSERT INTO kulupmac (kulupID, macID)
VALUES (15, currval('mac_macid_seq'));
INSERT INTO kulupmac (kulupID, macID)
VALUES (6, currval('mac_macid_seq'));
INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Bahattin', 'Şimşek', 50, 'H');
INSERT INTO Hakem (kisiID)
VALUES (currval('kisi_kisiid_seq'));
INSERT INTO machakem (macID, hakemID)
VALUES (currval('mac_macid_seq'), currval('kisi_kisiid_seq'));

INSERT INTO mac (ligID, evID, depID, skorEv, skorDep)
VALUES (1, 5, 1, 3, 4);
INSERT INTO kulupmac (kulupID, macID)
VALUES (5, currval('mac_macid_seq'));
INSERT INTO kulupmac (kulupID, macID)
VALUES (1, currval('mac_macid_seq'));
INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Zorbay', 'Küçük', 50, 'H');
INSERT INTO Hakem (kisiID)
VALUES (currval('kisi_kisiid_seq'));
INSERT INTO machakem (macID, hakemID)
VALUES (currval('mac_macid_seq'), currval('kisi_kisiid_seq'));

INSERT INTO mac (ligID, evID, depID, skorEv, skorDep)
VALUES (1, 2, 14, 1, 0);
INSERT INTO kulupmac (kulupID, macID)
VALUES (2, currval('mac_macid_seq'));
INSERT INTO kulupmac (kulupID, macID)
VALUES (14, currval('mac_macid_seq'));
INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Kaan', 'Numanoğlu', 50, 'H');
INSERT INTO Hakem (kisiID)
VALUES (currval('kisi_kisiid_seq'));
INSERT INTO machakem (macID, hakemID)
VALUES (currval('mac_macid_seq'), currval('kisi_kisiid_seq'));

INSERT INTO mac (ligID, evID, depID, skorEv, skorDep)
VALUES (1, 7, 9, 0, 0);
INSERT INTO kulupmac (kulupID, macID)
VALUES (7, currval('mac_macid_seq'));
INSERT INTO kulupmac (kulupID, macID)
VALUES (9, currval('mac_macid_seq'));
INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Kadir', 'Sağlam', 50, 'H');
INSERT INTO Hakem (kisiID)
VALUES (currval('kisi_kisiid_seq'));
INSERT INTO machakem (macID, hakemID)
VALUES (currval('mac_macid_seq'), currval('kisi_kisiid_seq'));

INSERT INTO mac (ligID, evID, depID, skorEv, skorDep)
VALUES (1, 17, 16, 1, 1);
INSERT INTO kulupmac (kulupID, macID)
VALUES (17, currval('mac_macid_seq'));
INSERT INTO kulupmac (kulupID, macID)
VALUES (16, currval('mac_macid_seq'));
INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Murat', 'Erdoğan', 50, 'H');
INSERT INTO Hakem (kisiID)
VALUES (currval('kisi_kisiid_seq'));
INSERT INTO machakem (macID, hakemID)
VALUES (currval('mac_macid_seq'), currval('kisi_kisiid_seq'));

INSERT INTO mac (ligID, evID, depID, skorEv, skorDep)
VALUES (1, 8, 19, 5, 1);
INSERT INTO kulupmac (kulupID, macID)
VALUES (8, currval('mac_macid_seq'));
INSERT INTO kulupmac (kulupID, macID)
VALUES (19, currval('mac_macid_seq'));
INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Direnç', 'Tonusluoğlu', 50, 'H');
INSERT INTO Hakem (kisiID)
VALUES (currval('kisi_kisiid_seq'));
INSERT INTO machakem (macID, hakemID)
VALUES (currval('mac_macid_seq'), currval('kisi_kisiid_seq'));

INSERT INTO mac (ligID, evID, depID, skorEv, skorDep)
VALUES (1, 3, 18, 1, 3);
INSERT INTO kulupmac (kulupID, macID)
VALUES (3, currval('mac_macid_seq'));
INSERT INTO kulupmac (kulupID, macID)
VALUES (18, currval('mac_macid_seq'));
INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Ümit', 'Öztürk', 50, 'H');
INSERT INTO Hakem (kisiID)
VALUES (currval('kisi_kisiid_seq'));
INSERT INTO machakem (macID, hakemID)
VALUES (currval('mac_macid_seq'), currval('kisi_kisiid_seq'));

INSERT INTO mac (ligID, evID, depID, skorEv, skorDep)
VALUES (1, 11, 10, 0, 0);
INSERT INTO kulupmac (kulupID, macID)
VALUES (11, currval('mac_macid_seq'));
INSERT INTO kulupmac (kulupID, macID)
VALUES (10, currval('mac_macid_seq'));
INSERT INTO kisi (ad, soyad, yas, kisiTipi)
VALUES ('Abdülkadir', 'Bitigen', 50, 'H');
INSERT INTO Hakem (kisiID)
VALUES (currval('kisi_kisiid_seq'));
INSERT INTO machakem (macID, hakemID)
VALUES (currval('mac_macid_seq'), currval('kisi_kisiid_seq'));