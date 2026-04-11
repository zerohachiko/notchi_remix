#!/usr/bin/env python3
import struct
import math
import wave
import os

SAMPLE_RATE = 44100

def generate_square_wave(freq, duration, volume=0.3, duty=0.5):
    samples = []
    num_samples = int(SAMPLE_RATE * duration)
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        phase = (t * freq) % 1.0
        value = volume if phase < duty else -volume
        samples.append(value)
    return samples

def generate_triangle_wave(freq, duration, volume=0.3):
    samples = []
    num_samples = int(SAMPLE_RATE * duration)
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        phase = (t * freq) % 1.0
        if phase < 0.5:
            value = volume * (4 * phase - 1)
        else:
            value = volume * (3 - 4 * phase)
        samples.append(value)
    return samples

def apply_envelope(samples, attack=0.005, decay=0.02, sustain_level=0.7, release=0.02):
    total = len(samples)
    attack_samples = int(SAMPLE_RATE * attack)
    decay_samples = int(SAMPLE_RATE * decay)
    release_samples = int(SAMPLE_RATE * release)
    sustain_samples = total - attack_samples - decay_samples - release_samples

    for i in range(total):
        if i < attack_samples:
            env = i / max(attack_samples, 1)
        elif i < attack_samples + decay_samples:
            progress = (i - attack_samples) / max(decay_samples, 1)
            env = 1.0 - (1.0 - sustain_level) * progress
        elif i < total - release_samples:
            env = sustain_level
        else:
            progress = (i - (total - release_samples)) / max(release_samples, 1)
            env = sustain_level * (1.0 - progress)
        samples[i] *= env
    return samples

def mix_samples(*sample_lists):
    max_len = max(len(s) for s in sample_lists)
    result = [0.0] * max_len
    for samples in sample_lists:
        for i, v in enumerate(samples):
            result[i] += v
    peak = max(abs(v) for v in result) or 1.0
    if peak > 0.95:
        result = [v * 0.95 / peak for v in result]
    return result

def pad_silence(duration):
    return [0.0] * int(SAMPLE_RATE * duration)

def save_wav(filename, samples):
    with wave.open(filename, 'w') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SAMPLE_RATE)
        for s in samples:
            s = max(-1.0, min(1.0, s))
            w.writeframes(struct.pack('<h', int(s * 32767)))

def generate_coin_sound():
    note1 = apply_envelope(generate_square_wave(988, 0.07, volume=0.35), attack=0.002, decay=0.01, sustain_level=0.8, release=0.01)
    note2 = apply_envelope(generate_square_wave(1319, 0.15, volume=0.35), attack=0.002, decay=0.01, sustain_level=0.6, release=0.05)
    samples = note1 + note2
    return samples

def generate_task_complete_sound():
    notes = [
        (523.25, 0.1),   # C5
        (659.25, 0.1),   # E5
        (783.99, 0.1),   # G5
        (1046.50, 0.15), # C6
        (783.99, 0.08),  # G5
        (1046.50, 0.25), # C6
    ]
    samples = []
    for freq, dur in notes:
        tone = apply_envelope(
            generate_square_wave(freq, dur, volume=0.3),
            attack=0.005, decay=0.01, sustain_level=0.7, release=0.02
        )
        samples.extend(tone)
    return samples

def generate_oneup_sound():
    notes = [
        (330, 0.06),   # E4
        (392, 0.06),   # G4
        (659, 0.06),   # E5
        (523, 0.06),   # C5
        (587, 0.06),   # D5
        (784, 0.12),   # G5
    ]
    samples = []
    for freq, dur in notes:
        tone = apply_envelope(
            generate_triangle_wave(freq, dur, volume=0.35),
            attack=0.003, decay=0.01, sustain_level=0.8, release=0.01
        )
        samples.extend(tone)
    return samples

def generate_power_up_sound():
    samples = []
    num_steps = 16
    base_freq = 200
    for i in range(num_steps):
        freq = base_freq + i * 60
        dur = 0.04
        tone = apply_envelope(
            generate_square_wave(freq, dur, volume=0.25),
            attack=0.002, decay=0.005, sustain_level=0.7, release=0.005
        )
        samples.extend(tone)
    return samples

if __name__ == "__main__":
    output_dir = os.path.join(os.path.dirname(__file__), "..", "notchi", "notchi", "Resources", "Sounds")
    os.makedirs(output_dir, exist_ok=True)

    coin = generate_coin_sound()
    save_wav(os.path.join(output_dir, "mario_coin.wav"), coin)
    print("Generated mario_coin.wav")

    complete = generate_task_complete_sound()
    save_wav(os.path.join(output_dir, "mario_complete.wav"), complete)
    print("Generated mario_complete.wav")

    oneup = generate_oneup_sound()
    save_wav(os.path.join(output_dir, "mario_oneup.wav"), oneup)
    print("Generated mario_oneup.wav")

    powerup = generate_power_up_sound()
    save_wav(os.path.join(output_dir, "mario_powerup.wav"), powerup)
    print("Generated mario_powerup.wav")

    print(f"\nAll sounds saved to: {output_dir}")
