"""
Main experiment
"""
import json
import os
import argparse
import torch
from torch.utils.data import DataLoader
from configparser import ConfigParser
from datetime import datetime

from lstm.lstm import FrictionLSTM
from utils.data import FrictionDataset

import wandb

def argparser():
    """
    Command line argument parser
    """
    parser = argparse.ArgumentParser(description='Friction LSTM')
    parser.add_argument(
        '--globals', type=str, default='./configs/globals.ini', 
        help="Path to the configuration file containing the global variables "
             "e.g. the paths to the data etc. See configs/globals.ini for an "
             "example."
    )
    return parser.parse_args()


def load_config(args):
    """
    Load .INI configuration files
    """
    config = ConfigParser()

    # Load global variable (e.g. paths)
    config.read(args.globals)

    # Load default model configuration
    default_model_config_filename = config['paths']['model_config_name']
    default_model_config_path = os.path.join(config['paths']['configs_directory'], default_model_config_filename)
    config.read(default_model_config_path)

    config.set('device', 'device', 'cuda' if torch.cuda.is_available() else 'cpu')

    return config


def run(config, trainloader, validatonloader, testloader, offline_test_free_loader=None, offline_test_collision_loader=None, devloader=None):
    current_time = datetime.now().strftime('%Y_%m_%d_%H_%M')
    checkpoint_directory = os.path.join(
        config['paths']['checkpoints_directory'],
        '{}{}/'.format(config['model']['name'], config['model']['config_id']),
        current_time)
    os.makedirs(checkpoint_directory, exist_ok=True)

    lstm = FrictionLSTM(config, checkpoint_directory)
    lstm.to(config['device']['device'])
    lstm.fit(trainloader, validatonloader)
    if offline_test_collision_loader is None or offline_test_collision_loader is None:
        lstm.test(testloader)
    else:
        lstm.test(testloader,offline_test_free_loader,offline_test_collision_loader)

if __name__ == '__main__':
    args = argparser()
    config = load_config(args)
    
    if config.getboolean("log", "wandb") is True:
        wandb.init(project="Friction LSTM", tensorboard=False)
        wandb_config_dict = dict()
        for section in config.sections():
            for key, value in config[section].items():
                wandb_config_dict[key] = value
        wandb.config.update(wandb_config_dict)

    # Get data path
    data_dir = config.get("paths", "data_directory")

    data_seq_len = config.getint("data", "seqeunce_length")
    data_num_input_feat = config.getint("data", "n_input_feature")
    data_num_output = config.getint("data", "n_output")

    train_data_file_name = config.get("paths", "train_data_file_name")
    train_csv_path = os.path.join(data_dir, train_data_file_name)
    train_data = FrictionDataset(train_csv_path,seq_len=data_seq_len, n_input_feat=data_num_input_feat, n_output=data_num_output)
    trainloader = DataLoader(
        train_data,
        batch_size=config.getint("training", "batch_size"),
        shuffle=True,
        drop_last=True,
        num_workers=8,
        pin_memory=True)

    validation_data_file_name = config.get("paths", "validation_data_file_name")
    validation_csv_path = os.path.join(data_dir, validation_data_file_name)
    validation_data = FrictionDataset(validation_csv_path,seq_len=data_seq_len, n_input_feat=data_num_input_feat, n_output=data_num_output)
    validationloader = DataLoader(
        validation_data,
        batch_size=config.getint("training", "batch_size"),
        shuffle=False,
        drop_last=True,
        num_workers=8,
        pin_memory=False)

    test_data_file_name = config.get("paths", "test_data_file_name")
    test_csv_path = os.path.join(data_dir, test_data_file_name)
    test_data = FrictionDataset(test_csv_path,seq_len=data_seq_len, n_input_feat=data_num_input_feat, n_output=data_num_output)
    testloader = DataLoader(
        test_data,
        batch_size=config.getint("training", "batch_size"),
        shuffle=False,
        drop_last=True,
        num_workers=8,
        pin_memory=False)

    if config.getboolean("offline_test", "offline_test") is True:
        offfline_test_free_data_file_name = config.get("paths", "offline_test_free_data_file_name")
        offline_test_free_csv_path = os.path.join(data_dir, offfline_test_free_data_file_name)
        offline_test_free_data = FrictionDataset(offline_test_free_csv_path,seq_len=data_seq_len, n_input_feat=data_num_input_feat, n_output=data_num_output)
        offline_test_free_loader = DataLoader(
            offline_test_free_data,
            batch_size=config.getint("training", "batch_size"),
            shuffle=False,
            drop_last=True,
            num_workers=8,
            pin_memory=False)

        offfline_test_collision_data_file_name = config.get("paths", "offline_test_collision_data_file_name")
        offline_test_collision_csv_path = os.path.join(data_dir, offfline_test_collision_data_file_name)
        offline_test_collision_data = FrictionDataset(offline_test_collision_csv_path,seq_len=data_seq_len, n_input_feat=data_num_input_feat, n_output=data_num_output)
        offline_test_collision_loader = DataLoader(
            offline_test_collision_data,
            batch_size=config.getint("training", "batch_size"),
            shuffle=False,
            drop_last=True,
            num_workers=8,
            pin_memory=False)

        run(config, trainloader, validationloader, testloader,offline_test_free_loader,offline_test_collision_loader)
        
    else:
        run(config, trainloader, validationloader, testloader)