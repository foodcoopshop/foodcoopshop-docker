<?php
declare(strict_types=1);

/**
 * - this file contains the specific configuration for your foodcoop
 * - configurations in config.php can be overriden in this file
 * - please rename it to "custom_config.php" to use it
 *
 * FoodCoopShop - The open source software for your foodcoop
 *
 * Licensed under the GNU Affero General Public License version 3
 * For full copyright and license information, please see LICENSE
 * Redistributions of files must retain the above copyright notice.
 *
 * @since         FoodCoopShop 1.0.0
 * @license       https://opensource.org/licenses/AGPL-3.0
 * @author        Mario Rothauer <office@foodcoopshop.com>
 * @copyright     Copyright (c) Mario Rothauer, https://www.rothauer-it.com
 * @link          https://www.foodcoopshop.com
 */

return [
    'debug' => false,
    'EmailTransport' => [
        'default' => [
            'className' => 'Smtp',
            'host' => 'ssl://REPLACEWITHYOUR.SERVER.COM',
            'port' => 465,
            'timeout' => 30,
            'username' => 'REPLACEWITHYOUR@MAIL.COM',
            'password' => trim(file_get_contents('/run/secrets/email_pass')), //Email SMTP authentication Docker secret
            'tls' => false, //This refers to opportunistic TLS (STARTTLS)
        ]
    ],
    'Email' => [
        'default' => [
            'transport' => 'default',
            'from' => ['REPLACEWITHYOUR@MAIL.COM' => 'REPLACEWITHYOURNAME'], // [email-address => name] syntax necessary (not only [email]
            'charset' => 'utf-8',
            'headerCharset' => 'utf-8',
        ]
    ],
    'Datasources' => [
        'default' => [
            'host' => 'YOURDBHOST',
            'username' => 'YOURDBUSER',
            'password' => trim(file_get_contents('/run/secrets/mysql_fcsdbpass')), //MySQL DB user Docker secret
            'database' => 'YOURDB',
        ]
    ],

    /**
     * A random string used in security hashing methods.
     */
    'Security' => [
        'salt' => trim(file_get_contents('/run/secrets/cakephp_salt')), //CakePHP salt Docker secret
        'cookieKey' => trim(file_get_contents('/run/secrets/cakephp_cookiekey')) //CakePHP cookieKey Docker secret
    ],

    'Cache' => [
        'default' => [
            'path' => '/tmp',
            'prefix' => 'example_com_default_',
        ],
        'short' => [
            'path' => '/tmp',
            'prefix' => 'example_com_short_',
        ],
        '_cake_translations_' => [
            'path' => '/tmp/persistent/',
            'prefix' => 'example_com_translations_',
        ],
        '_cake_model_' => [
            'path' => '/tmp/models/',
            'prefix' => 'example_com_model_',
        ],
    ],

    'App' => [
        'fullBaseUrl' => 'https://YOUR.SHOP-DOMAIN.COM',
    ],

    'app' => [

        'discourseSsoEnabled' => false,

        /**
         * A random string used for Discourse SSO
         */
        'discourseSsoSecret' => '',

        /**
         * cronjob needs to be activated / deactivated too if you change emailOrderReminderEnabled
         * @see https://foodcoopshop.github.io/en/cronjobs
         */
        'emailOrderReminderEnabled' => true,

        /**
         * valid options of array: 'cashless' or 'cash' (or both but this is not recommended)
         */
        'paymentMethods' => [
            'cashless'
        ]

    ],
    // 'Log' => [
    //     'debug' => [
    //         'className' => 'File',
    //         'path' => LOGS,
    //         'file' => 'debug',
    //         'levels' => ['notice', 'info', 'debug'],
    //     ],
    //     'error' => [
    //         'className' => 'File',
    //         'path' => LOGS,
    //         'file' => 'error',
    //         'levels' => ['warning', 'error', 'critical', 'alert', 'emergency'],
    //     ]
    // ],
];
