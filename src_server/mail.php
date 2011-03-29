<?php

/**
 * Standard PHP mailer.
 *
 * NOTE:
 * All arguments can be passed via post data or url variables.
 * All email address can be given straigt e.g. matan@example.com or with name attached e.g. Matan Uberstein <matan@example.com>.
 *
 * Required arguments are:
 * @param from - The source email address. e.g. matan@example.com or Matan Uberstein <matan@example.com>
 * @param to - A comma separated list of destination email addresses.
 * @param subject - The subject of the email.
 * @param type - The format of the email message. Options are: text/html or text/plain.
 * @param mimeVersion - The MIME-Version included in the header of the email.
 *
 * Optional argumetns are:
 * @param cc - A comma separated list of destination email addresses.
 * @param bcc - A comma separated list of destination email addresses.
 * @param charset - The characher encoding of the email messsage. This is required if the type is set ot text/html.
 * @param message - The body of the email, can be in plain text of html format.
 * @param messageURL - The server can load in the email message directly from the url passed.
 */

if(!isset($_REQUEST['from'], $_REQUEST['to'], $_REQUEST['subject'], $_REQUEST['mimeVersion'], $_REQUEST['type'])) {
    echo 'Required variables not set!';
    exit();
}

if(!isset($_REQUEST['message']) && !isset($_REQUEST['messageURL'])) {
    echo 'Param "message" or "messageURL" must be set!';
    exit();
}

if($_REQUEST['type'] == 'text/html' || $_REQUEST['type'] == 'text/plain') {
    if($_REQUEST['type'] == 'text/html' && !isset($_REQUEST['charset'])) {
        echo 'If mail type set to "text/html", a Charset must be defined.';
        exit();
    }
    if(isset($_REQUEST['message'])) {
        $message = $_REQUEST['message'];
    } else {
        $message = "";
        try {
            $fh = fopen($_REQUEST['messageURL'], 'r');
            while(!feof($fh)) {
                $message .= fgets($fh, 4096);
            }
            fclose($fh);
        } catch (Exception $err) {
            echo $err;
			exit();
        }
    }
} else {
    echo 'Mail type not recognized. Options are: "text/html" or "text/plain".';
    exit();
}

$line_break = "\r\n";

// To send HTML mail, the Content-type header must be set
$headers = 'MIME-Version: ' . $_REQUEST['mimeVersion'] . $line_break;
if($_REQUEST['type'] == 'text/html') {
    $headers .= 'Content-type: ' . $_REQUEST['type'] . '; charset=' . $_REQUEST['charset'] . $line_break;
}

// Additional headers
$headers .= 'From: ' . $_REQUEST['from'] . $line_break;
if(isset($_REQUEST['cc'])) {
    $headers .= 'Cc: ' . $_REQUEST['cc'] . $line_break;
}
if(isset($_REQUEST['bcc'])) {
    $headers .= 'Bcc: ' . $_REQUEST['bcc'] . $line_break;
}

// Mail it
$success = mail($_REQUEST['to'], $_REQUEST['subject'], $message, $headers);
if($success) {
    echo('true');
} else {
    echo('Could not send mail.');
}
?>
