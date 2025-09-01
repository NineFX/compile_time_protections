use core::str;
use rand::seq::IndexedRandom;
use std::fs::{File, OpenOptions};
use std::io::Write;
use std::process::{Command, Output};
use std::{thread, time};

#[derive(Debug)]
enum VulnerableBinaryCall {
    Normal,
    //BadCast,
    //UseAfterFree,
    IntegerOverflow,
    StrcpyOutOfBound,
}

const VULNERABLE_BINARY_PATH: &str = "vulnerable_binary";
const LOG_PATH: &str = "/tmp/toy_service_log.txt";
const SUCCESS_PATH: &str = "/tmp/toy_service_success.txt";
const SLEEP_SECONDS: u64 = 5;

fn main() {
    println!("Starting Toy Service");
    let mut open_opts = OpenOptions::new();
    let append_open_opts = open_opts.append(true).create(true);
    let log_file = append_open_opts.open(LOG_PATH).unwrap();
    let success_file = append_open_opts.open(SUCCESS_PATH).unwrap();
    let sleep_duration = time::Duration::from_secs(SLEEP_SECONDS);
    let mut rng = rand::rng();
    let call_types = vec![
        VulnerableBinaryCall::Normal,
        //VulnerableBinaryCall::BadCast,
        //VulnerableBinaryCall::UseAfterFree,
        VulnerableBinaryCall::IntegerOverflow,
        VulnerableBinaryCall::StrcpyOutOfBound,
    ];
    loop {
        let call = call_types.choose(&mut rng).unwrap();
        call_binary(VULNERABLE_BINARY_PATH, call, &success_file, &log_file);
        thread::sleep(sleep_duration);
    }
}

fn call_binary(
    path: &str,
    call: &VulnerableBinaryCall,
    mut success_file: &File,
    mut log_file: &File,
) {
    let call = match call {
        VulnerableBinaryCall::IntegerOverflow => Some("integer_overflow"),
        //VulnerableBinaryCall::BadCast => Some("bad_cast"),
        VulnerableBinaryCall::Normal => None,
        //VulnerableBinaryCall::UseAfterFree => Some("use_after_free"),
        VulnerableBinaryCall::StrcpyOutOfBound => Some("strcpy_out_of_bounds"),
    };
    let output = command(path.to_string(), call).unwrap();
    if output.status.success() {
        success_file.write(&output.stdout).unwrap();
    } else {
        log_file.write(&output.stderr).unwrap();
    }
}

fn command(path: String, argument: Option<&str>) -> Result<Output, std::io::Error> {
    let mut cmd: Command = Command::new(path);
    let output = match argument {
        Some(arg) => cmd.arg(arg).output(),
        None => cmd.output(),
    };
    return output;
}
