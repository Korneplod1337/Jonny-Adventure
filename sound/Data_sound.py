import pygame as pg
from configparser import ConfigParser


class SoundManager:
    def __init__(self):
        self.sound_now = False
        pg.mixer.init()
        self.sounds = {}
        self.music_tracks = {}
        self.load_sounds()
        self.load_music()
        self.config = ConfigParser()
        self.config.read('files/Jonny_conf.ini')

    def load_sounds(self):
        self.sounds['ultrasound'] = pg.mixer.Sound('sound/ultrasoundtrackus5.mp3')

    def load_music(self):
        self.music_tracks['arcade'] = 'sound/arcade.ogg'
        self.music_tracks['creepy'] = 'sound/creepy.ogg'
        self.music_tracks['main-menu'] = 'sound/main-menu.ogg'

    def play_sound(self, sound_name):
        if sound_name in self.sounds:
            self.sounds[sound_name].play()

    def play_music(self, track_name, loops=-1):
        if not self.sound_now:
            if track_name in self.music_tracks:
                pg.mixer.music.load(self.music_tracks[track_name])
                pg.mixer.music.play(loops)
                self.sound_now = True

    def set_sound_volume(self, sound_name, volume):
        if sound_name in self.sounds:
            self.sounds[sound_name].set_volume(volume)

    def set_music_volume(self, volume):
        pg.mixer.music.set_volume(volume)

    def get_sound_volume(self, sound_name):
        if sound_name in self.sounds:
            return self.sounds[sound_name].get_volume()
        return None

    def get_music_volume(self):
        return self.config['MY_VOLUME']['volume_sound']


    def pause_music(self):
        pg.mixer.music.pause()

    def unpause_music(self):
        pg.mixer.music.unpause()

    def stop_music(self):
        pg.mixer.music.stop()
        self.sound_now = False


sound_manager = SoundManager()
